class Booking {
  final String? id;
  final String service;
  final DateTime date;
  final String timeSlot;
  final String name;
  final String email;

  const Booking({
    this.id,
    required this.service,
    required this.date,
    required this.timeSlot,
    required this.name,
    required this.email,
  });

  Map<String, dynamic> toJson() => {
        'service': service,
        'date': date.toIso8601String().split('T').first,
        'time_slot': timeSlot,
        'name': name,
        'email': email,
      };
}