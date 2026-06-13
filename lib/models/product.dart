class Product {
  final String id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final double? originalPrice;
  final String description;
  final List<String> sizes;
  final List<ProductColor> colors;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final bool isNew;
  final bool isBestseller;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    this.originalPrice,
    required this.description,
    required this.sizes,
    required this.colors,
    required this.images,
    required this.rating,
    required this.reviewCount,
    this.isNew = false,
    this.isBestseller = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'],
        name: json['name'],
        brand: json['brand'] ?? '',
        category: json['category'] ?? '',
        price: (json['price'] as num).toDouble(),
        originalPrice: json['original_price'] != null
            ? (json['original_price'] as num).toDouble()
            : null,
        description: json['description'] ?? '',
        sizes: List<String>.from(json['sizes'] ?? []),
        colors: (json['colors'] as List? ?? [])
            .map((c) => ProductColor.fromJson(c))
            .toList(),
        images: List<String>.from(json['images'] ?? []),
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: json['review_count'] ?? 0,
        isNew: json['is_new'] ?? false,
        isBestseller: json['is_bestseller'] ?? false,
      );

  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  int get discountPercent => hasDiscount
      ? (((originalPrice! - price) / originalPrice!) * 100).round()
      : 0;
}

class ProductColor {
  final String name;
  final int hex;

  const ProductColor({required this.name, required this.hex});

  factory ProductColor.fromJson(Map<String, dynamic> json) => ProductColor(
        name: json['name'],
        hex: int.parse(
          json['hex'].toString().replaceAll('#', ''),
          radix: 16,
        ) + 0xFF000000,
      );
}