class SensorData {
  /// Accelerazione lineare filtrata (m/s²)
  final double accelX;
  final double accelY;
  final double accelZ;

  /// Velocità angolare filtrata (°/s)
  final double gyroX;
  final double gyroY;
  final double gyroZ;

  /// Timestamp della lettura
  final DateTime timestamp;

  SensorData({
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => '''
Accelerometer (linear, filtered):
 X: ${accelX.toStringAsFixed(2)}
 Y: ${accelY.toStringAsFixed(2)}
 Z: ${accelZ.toStringAsFixed(2)}

Gyroscope (filtered):
 X: ${gyroX.toStringAsFixed(2)}
 Y: ${gyroY.toStringAsFixed(2)}
 Z: ${gyroZ.toStringAsFixed(2)}
Timestamp: $timestamp
''';
}