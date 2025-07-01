import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Seleziona dispositivo', style: TextStyle(fontWeight: FontWeight.normal)),
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
                      leading: const Icon(Icons.bluetooth, color: Colors.blueGrey),
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

    final backgroundColor = const Color(0xFFF8F8F8);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: backgroundColor,
      body: Container(
        color: backgroundColor,
        child: Column(
          children: [
            const SizedBox(height: kToolbarHeight + 34),
            StreamBuilder<bool>(
              stream: ble.connectionStream,
              initialData: ble.isConnected,
              builder: (ctx, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                final connected = snap.data!;
                return Container(
                  width: double.infinity,
                  color: connected ? Colors.green[100]?.withOpacity(0.6) : Colors.red[100]?.withOpacity(0.6),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: Text(
                    connected
                        ? '✔ Dispositivo BLE connesso'
                        : '⚠ Dispositivo BLE disconnesso',
                    style: TextStyle(
                      color: connected ? Colors.green[900] : Colors.red[900],
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
            Expanded(
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Color(0xff6750a4),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xff6750a4).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            italianLabels[session.currentPrediction] ?? 'INATTIVO',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: session.currentPrediction == 'AGGRESSIVE'
                                  ? Colors.red
                                  : session.currentPrediction == 'NORMAL'
                                  ? Colors.orangeAccent
                                  : session.currentPrediction == 'SLOW'
                                  ? Colors.green[900]
                                  : Color(0xff6750a4),
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 24),
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
                                ? Colors.orangeAccent
                                : session.currentPrediction == 'SLOW'
                                ? Colors.green[900]
                                : Color(0xff6750a4),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xff6750a4),
                              foregroundColor: backgroundColor,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            onPressed: () async {
                              try {
                                if (session.isSessionActive) {
                                  await session.stopSession();
                                  setState(() => _isConnected = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      duration: const Duration(seconds: 6),
                                      content: Row(
                                        children: const [
                                          Icon(Icons.check_circle, color: Colors.white, size: 28),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Sessione terminata correttamente!\nReport e manutenzione disponibili nelle sezioni dedicate.',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Color(0xff6750a4),
                                    ),
                                  );
                                } else {
                                  if (!_isConnected) {
                                    await _selectAndConnect();
                                  }
                                  if (_isConnected) {
                                    await session.startSession();
                                  }
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Errore: ${e.toString()}"),
                                  ),
                                );
                              }
                            },
                            icon: Icon(session.isSessionActive ? Icons.stop : Icons.play_arrow),
                            label: Text(session.isSessionActive ? 'Termina sessione' : 'Avvia sessione'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: Color(0xff6750a4),
          elevation: 0,
          title: Text(
            'Stile di guida',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: backgroundColor,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                _isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                color: backgroundColor,
              ),
              onPressed: _isConnected ? null : _selectAndConnect,
            ),
          ],
        ),
      ),
    );
  }
}
