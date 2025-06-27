class Behavior {
  final DateTime timestamp;
  final String label;
  final double accelX, accelY, accelZ;
  final double gyroX, gyroY, gyroZ;

  Behavior({
    required this.timestamp,
    required this.label,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ
  });

  factory Behavior.fromJson(Map<String, dynamic> j) {
    final raw = j['timestamp'] as String;

    DateTime dt = DateTime.parse(raw);

    final offset = DateTime.now().timeZoneOffset;

    dt = dt.add(offset);

    return Behavior(
      timestamp: dt,
      label: j['label'] as String,
      accelX: (j['accelX'] as num).toDouble(),
      accelY: (j['accelY'] as num).toDouble(),
      accelZ: (j['accelZ'] as num).toDouble(),
      gyroX:  (j['gyroX'] as num).toDouble(),
      gyroY:  (j['gyroY'] as num).toDouble(),
      gyroZ:  (j['gyroZ'] as num).toDouble(),
    );
  }

  /// Mappa in valore numerico per il grafico
  double get numericValue {
    switch (label) {
      case 'SLOW':       return 0.0;
      case 'NORMAL':     return 1.0;
      case 'AGGRESSIVE': return 2.0;
      default:           return 1.0;
    }
  }
}