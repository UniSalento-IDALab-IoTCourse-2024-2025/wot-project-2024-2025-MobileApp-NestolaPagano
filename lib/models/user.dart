class User {
  final String id;
  final String email;
  final String full_name;
  final DateTime registrationDate;
  final double? maintenanceUrgency;

  User({
    required this.id,
    required this.email,
    required this.full_name,
    required this.registrationDate,
    this.maintenanceUrgency,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      full_name: json['full_name'] as String,
      registrationDate: DateTime.parse(json['registration_date']  as String),
      maintenanceUrgency: json['maintenance_urgency'] != null
          ? (json['maintenance_urgency'] as num).toDouble()
          : null,
    );
  }
}