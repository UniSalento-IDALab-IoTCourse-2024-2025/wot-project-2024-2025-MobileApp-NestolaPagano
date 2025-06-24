import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';
import '../ble/bluetooth_manager.dart';
import '../ble/thingy_ble.dart';
import '../services/driving_session_manager.dart';

class SensorDashboard extends StatefulWidget {
  const SensorDashboard({super.key});

  @override
  State<SensorDashboard> createState() => _SensorDashboardState();
}

class _SensorDashboardState extends State<SensorDashboard> {
  late final BluetoothManager _bleManager;
  final _parser = ThingyBleParser();
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _bleManager = Provider.of<BluetoothManager>(context, listen: false);
  }

  Future<void> _selectAndConnect() async {
    final ble = Provider.of<BluetoothManager>(context, listen: false);
    await ble.startScan();

    final selected = await showDialog<DiscoveredDevice>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Seleziona dispositivo'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: StreamBuilder<List<DiscoveredDevice>>(
              stream: ble.scanStream,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final devices = snap.data ?? [];
                if (devices.isEmpty) {
                  return const Center(child: Text('Nessun dispositivo trovato'));
                }
                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, i) {
                    final device = devices[i];
                    return ListTile(
                      title: Text(device.name.isEmpty ? device.id : device.name),
                      subtitle: Text(device.id),
                      leading: const Icon(Icons.bluetooth),
                      onTap: () => Navigator.of(ctx).pop(device),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );

    if (selected != null) {
      ble.connectTo(selected, (data) {
        final parsed = ThingyBleParser().parse(data);
        Provider.of<DrivingSessionManager>(context, listen: false)
            .addSensorData(parsed);
      });

      setState(() => _isConnected = true);
    }
  }

  @override
  void dispose() {
    _bleManager.dispose();
    super.dispose();
  }

  final Map<String, String> italianLabels = {
    'AGGRESSIVE': 'AGGRESSIVO',
    'NORMAL': 'NORMALE',
    'SLOW': 'CAUTO'
  };

  @override
  Widget build(BuildContext context) {
    final session = context.watch<DrivingSessionManager>();
    final ble = Provider.of<BluetoothManager>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stile di guida'),
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.bluetooth_connected : Icons.bluetooth),
            onPressed: _isConnected ? null : _selectAndConnect,
          )
        ],
      ),

      body: Column(
        children: [
          StreamBuilder<bool>(
            stream: ble.connectionStream,
            initialData: ble.isConnected,
            builder: (ctx, snap) {
              if (!snap.hasData) {
                return const SizedBox.shrink();
              }
              final connected = snap.data!;

              if (connected) {
                return Container(
                  width: double.infinity,
                  color: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: const Text(
                    '✔ Dispositivo BLE connesso',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                );
              } else {
                return Container(
                  width: double.infinity,
                  color: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: const Text(
                    '⚠ Dispositivo BLE disconnesso',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                );
              }
            },
          ),

          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    italianLabels[session.currentPrediction]
                        ?? session.currentPrediction,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 20),
                  Icon(
                    session.currentPrediction == 'AGGRESSIVE'
                        ? Icons.sentiment_very_dissatisfied
                        : session.currentPrediction == 'NORMAL'
                        ? Icons.sentiment_satisfied
                        : session.currentPrediction == 'SLOW'
                        ? Icons.sentiment_very_satisfied
                        : Icons.sentiment_neutral,
                    size: 80,
                    color: session.currentPrediction == 'AGGRESSIVE'
                        ? Colors.red
                        : session.currentPrediction == 'NORMAL'
                        ? Colors.orange
                        : session.currentPrediction == 'SLOW'
                        ? Colors.green
                        : Colors.grey,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        if (session.isSessionActive) {
                          await session.stopSession();
                          setState(() => _isConnected = false);
                        } else {
                          if (!_isConnected) {
                            await _selectAndConnect();
                          }
                          await session.startSession();
                        }
                      } catch (e, st) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Errore: ${e.toString()}"))
                        );
                      }
                    },
                    child: Text(session.isSessionActive ? 'Termina sessione' : 'Avvia sessione'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}