class Behavior {
  final DateTime timestamp;
  final String label;

  Behavior({
    required this.timestamp,
    required this.label,
  });

  factory Behavior.fromJson(Map<String, dynamic> j) {
    return Behavior(
      timestamp: DateTime.parse(j['timestamp'] as String),
      label: j['label'] as String,
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