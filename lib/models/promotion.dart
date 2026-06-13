class Promotion {
  final String id;
  final String title;
  final String description;
  final String code;
  final int discountPercent;
  final DateTime expiryDate;
  final String? imageUrl;

  const Promotion({
    required this.id,
    required this.title,
    required this.description,
    required this.code,
    required this.discountPercent,
    required this.expiryDate,
    this.imageUrl,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) => Promotion(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        code: json['code'],
        discountPercent: json['discount_percent'],
        expiryDate: DateTime.parse(json['expiry_date']),
        imageUrl: json['image_url'],
      );

  bool get isExpired => expiryDate.isBefore(DateTime.now());
}