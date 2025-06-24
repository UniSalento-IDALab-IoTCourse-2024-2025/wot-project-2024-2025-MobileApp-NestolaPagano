import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

typedef RawDataCallback = void Function(List<int> data);

class BluetoothManager {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  final _scanController = StreamController<List<DiscoveredDevice>>.broadcast();
  Stream<List<DiscoveredDevice>> get scanStream => _scanController.stream;

  final Map<String, DiscoveredDevice> _foundDevices = {};

  DiscoveredDevice? _connectedDevice;
  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connectionSub;

  final Uuid thingyService = Uuid.parse("ef680400-9b35-4933-9b10-52ffa9740042");
  final Uuid rawChar      = Uuid.parse("ef680406-9b35-4933-9b10-52ffa9740042");

  bool get isConnected => _connectedDevice != null;

  final _connController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connController.stream;

  Future<void> startScan() async {
    await Permission.locationWhenInUse.request();
    if (await Permission.bluetoothScan.request().isDenied ||
        await Permission.bluetoothConnect.request().isDenied) {
      print('Bluetooth permissions denied');
      return;
    }

    _scanSub?.cancel();
    _foundDevices.clear();

    _scanSub = _ble
        .scanForDevices(withServices: [])
        .listen((device) {
      if (device.name.toLowerCase().startsWith('thin')) {
        _foundDevices[device.id] = device;
        _scanController.add(_foundDevices.values.toList());
      }
    }, onError: (e) {
      print("Scan error: $e");
    });
  }

  Future<void> connectTo(DiscoveredDevice device, RawDataCallback onData) async {
    await _disconnect();

    _connectedDevice = device;
    _connectionSub = _ble.connectToDevice(id: device.id).listen((state) async {
      if (state.connectionState == DeviceConnectionState.connected) {
        _connController.add(true);
        await _discoverAndSubscribe(device, onData);
      } else if (state.connectionState == DeviceConnectionState.disconnected) {
        _connController.add(false);
        _connectedDevice = null;
      }
    }, onError: (e) {
      print("Connection error: $e");
    });
  }

  Future<void> _discoverAndSubscribe(DiscoveredDevice device, RawDataCallback onData) async {
    try {
      await _ble.discoverAllServices(device.id);
      final services = await _ble.getDiscoveredServices(device.id);

      for (var service in services) {
        if (service.id == thingyService) {
          for (var char in service.characteristics) {
            if (char.id == rawChar) {
              final qc = QualifiedCharacteristic(
                serviceId: service.id,
                characteristicId: char.id,
                deviceId: device.id,
              );
              _ble.subscribeToCharacteristic(qc)
                  .listen(onData, onError: (e) => print("Sub error: $e"));
            }
          }
        }
      }
    } catch (e) {
      print("Discovery/subscription failed: $e");
    }
  }

  Future<void> _disconnect() async {
    await _scanSub?.cancel();
    await _connectionSub?.cancel();
    _connectedDevice = null;
    _connController.add(false);
  }

  void dispose() {
    _scanSub?.cancel();
    _connectionSub?.cancel();
    _scanController.close();
  }
}