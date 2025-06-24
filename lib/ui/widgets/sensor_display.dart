import 'package:flutter/material.dart';
import '../../models/sensor_data.dart';

class SensorDisplay extends StatelessWidget {
  final SensorData data;

  const SensorDisplay({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Timestamp: ${data.timestamp.year.toString().padLeft(4, '0')}-'
            '${data.timestamp.month.toString().padLeft(2, '0')}-'
            '${data.timestamp.day.toString().padLeft(2, '0')} '
            '${data.timestamp.hour.toString().padLeft(2, '0')}:'
            '${data.timestamp.minute.toString().padLeft(2, '0')}:'
            '${data.timestamp.second.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 16),
        Text('Accelerometer',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(' X: ${data.accelX.toStringAsFixed(2)} m/s²'),
        Text(' Y: ${data.accelY.toStringAsFixed(2)} m/s²'),
        Text(' Z: ${data.accelZ.toStringAsFixed(2)} m/s²'),
        const SizedBox(height: 12),
        Text('Gyroscope',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(' X: ${data.gyroX.toStringAsFixed(2)} rad/s'),
        Text(' Y: ${data.gyroY.toStringAsFixed(2)} rad/s'),
        Text(' Z: ${data.gyroZ.toStringAsFixed(2)} rad/s'),
      ],
    );
  }
}