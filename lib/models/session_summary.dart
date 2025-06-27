class SessionSummary {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final double? maintenanceUrgency;

  SessionSummary({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.maintenanceUrgency,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> j) {
    DateTime parseAndOffset(String raw) {
      DateTime dt = DateTime.parse(raw);

      return dt.add(DateTime.now().timeZoneOffset);
    }

    double? urg;
    if (j.containsKey('maintenance_urgency') && j['maintenance_urgency'] != null) {
      urg = (j['maintenance_urgency'] as num).toDouble();
    }

    return SessionSummary(
      id: j['id'] as String,
      startTime: parseAndOffset(j['start_time'] as String),
      endTime:   parseAndOffset(j['end_time']   as String),
      maintenanceUrgency: urg,
    );
  }
}