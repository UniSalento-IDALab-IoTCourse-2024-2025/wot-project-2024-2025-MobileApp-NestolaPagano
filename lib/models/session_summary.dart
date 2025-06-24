class SessionSummary {
  final String id;
  final DateTime startTime;
  final DateTime endTime;

  SessionSummary({
    required this.id,
    required this.startTime,
    required this.endTime,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> j) {
    return SessionSummary(
      id: j['id'] as String,
      startTime: DateTime.parse(j['start_time'] as String),
      endTime: DateTime.parse(j['end_time'] as String),
    );
  }
}