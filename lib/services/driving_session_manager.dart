import 'dart:async';
import 'dart:convert';
import 'package:app/services/auth_headers_mixin.dart';
import 'package:app/services/report_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import '../models/sensor_data.dart';

class DrivingSessionManager with ChangeNotifier, AuthHeadersMixin {

  final int samplingRate = 2;
  final int windowDurationSec = 10;
  final int stepDurationSec = 1;

  static const _baseUrl = 'http://192.168.254.37:8000/api';
  final Uri _sessionStartUrl = Uri.parse('$_baseUrl/sessions/');
  final Uri _sessionStopUrl = Uri.parse('$_baseUrl/sessions/stop');
  final Uri websocketUrl = Uri.parse('ws://192.168.254.37:8000/api/behavior/');

  final List<SensorData> _buffer = [];
  Timer? _samplingTimer;
  WebSocketChannel? _wsChannel;

  bool    _sessionActive    = false;
  String? _currentSessionId;
  String  _currentPrediction = 'INATTIVO';

  double? _lastKnownMaintenanceScore;

  bool get isSessionActive => _sessionActive;
  String get currentPrediction => _currentPrediction;

  Future<void> startSession() async {
    try {
      final reportService = ReportService();
      final user = await reportService.updateMaintenanceUrgency();
      _lastKnownMaintenanceScore = user.maintenanceUrgency;
    } catch (e) {
      debugPrint('Impossibile ottenere maintenanceUrgency iniziale: $e');
      _lastKnownMaintenanceScore = null;
    }

    final headers = await authHeaders();
    final resp = await http.post(
      _sessionStartUrl,
      headers: headers,
      body: jsonEncode({}),
    );
    if (resp.statusCode != 201) {
      throw Exception('Impossibile avviare sessione (${resp.statusCode})');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    _currentSessionId = data['id'] as String;

    _buffer.clear();
    _connectWebSocket();
    _sessionActive = true;
    _startSamplingLoop();
    notifyListeners();
  }

  Future<void> stopSession() async {
    final headers = await authHeaders();
    _samplingTimer?.cancel();
    _wsChannel?.sink.close();

    if (_currentSessionId != null) {
      await http.patch(
        _sessionStopUrl,
        headers: headers,
        body: jsonEncode({'session_id': _currentSessionId}),
      );
    }

    _sessionActive = false;
    _currentSessionId = null;
    _currentPrediction = 'INATTIVO';
    notifyListeners();

    try {
      final reportService = ReportService();
      final updatedUser = await reportService.updateMaintenanceUrgency();
      final double? newScore = updatedUser.maintenanceUrgency;

      if (_lastKnownMaintenanceScore != null &&
          newScore != null &&
          (( _lastKnownMaintenanceScore! * 100).round() != (newScore * 100).round() )) {

        const notifDetails = NotificationDetails(
          android: AndroidNotificationDetails(
            'maintenance_channel',
            'Manutenzione',
            channelDescription: 'Notifiche sullo stato di manutenzione',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            visibility: NotificationVisibility.public,
          ),
        );

        await flutterLocalNotificationsPlugin.show(
          0,
          'Aggiornamento manutenzione',
          'La predizione della manutenzione è stata aggiornata.',
          notifDetails,
        );
      }

      _lastKnownMaintenanceScore = newScore;
    } catch (e) {
      debugPrint('Errore durante il controllo manutenzione: $e');
    }
  }

  void addSensorData(SensorData data) {
    if (!_sessionActive) return;
    _buffer.add(data);
    final maxLen = samplingRate * windowDurationSec;
    if (_buffer.length > maxLen) _buffer.removeAt(0);
  }

  void _startSamplingLoop() {
    _samplingTimer = Timer.periodic(
      Duration(seconds: stepDurationSec),
          (_) => _sendWindowToServer(),
    );
  }

  void _connectWebSocket() {
    _wsChannel = WebSocketChannel.connect(websocketUrl);
    _wsChannel!.stream.listen((message) async {
      final jsonMsg = json.decode(message) as Map<String, dynamic>;
      if (jsonMsg['type'] == 'prediction') {
        _currentPrediction = jsonMsg['label'] as String;
        notifyListeners();
      }
    });
  }

  void _sendWindowToServer() {
    if (_buffer.length < samplingRate * windowDurationSec) return;
    final payload = _buffer.map((d) => {
      'AccX': d.accelX,
      'AccY': d.accelY,
      'AccZ': d.accelZ,
      'GyroX': d.gyroX,
      'GyroY': d.gyroY,
      'GyroZ': d.gyroZ,
      'timestamp': d.timestamp.toIso8601String(),
    }).toList();
    _wsChannel?.sink.add(json.encode({
      'type': 'window',
      'payload': payload,
      'session_id': _currentSessionId,
    }));
  }
}