class Branch {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String phone;
  final String hours;
  final double distanceKm;

  const Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.phone,
    required this.hours,
    required this.distanceKm,
  });

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
        id: json['id'],
        name: json['name'],
        address: json['address'],
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        phone: json['phone'] ?? '',
        hours: json['hours'] ?? '',
        distanceKm: (json['distance_km'] as num).toDouble(),
      );
}