class Lookbook {
  final String id;
  final String title;
  final String imageUrl;
  final List<String> productIds;

  const Lookbook({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.productIds,
  });

  factory Lookbook.fromJson(Map<String, dynamic> json) => Lookbook(
        id: json['id'],
        title: json['title'],
        imageUrl: json['image_url'],
        productIds: List<String>.from(json['product_ids'] ?? []),
      );
}