import 'dart:convert';
import 'package:app/services/auth_headers_mixin.dart';
import 'package:http/http.dart' as http;
import '../models/session_summary.dart';
import '../models/behavior.dart';
import '../models/user.dart';

class ReportService with AuthHeadersMixin {
  static const _baseUrl = 'http://192.168.254.37:8000/api';

  /// Elenco sessioni
  Future<List<SessionSummary>> fetchSessions() async {
    final uri = Uri.parse('$_baseUrl/sessions/');
    final headers = await authHeaders();

    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Errore caricamento sessioni (${resp.statusCode})');
    }
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list
        .map((e) => SessionSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lista behaviors di una sessione
  Future<List<Behavior>> fetchBehaviors(String sessionId) async {
    final uri = Uri.parse('$_baseUrl/sessions/$sessionId/behaviors');
    final headers = await authHeaders();

    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception(
          'Errore caricamento behaviors (${resp.statusCode})'
      );
    }
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list
        .map((e) => Behavior.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SessionSummary> fetchSessionDetail(String sessionId) async {
    final uri = Uri.parse('$_baseUrl/sessions/$sessionId');
    final headers = await authHeaders();

    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Errore caricamento sessione (${resp.statusCode})');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return SessionSummary.fromJson(data);
  }


  Future<User> updateMaintenanceUrgency() async {
    final uri = Uri.parse('$_baseUrl/report/update_maintenance');
    final headers = await authHeaders();

    final resp = await http.post(uri, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Errore aggiornamento maintenance_urgency (${resp.statusCode})');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return User.fromJson(data);
  }
}