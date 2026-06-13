enum FitFeedback { runsSmall, trueToSize, runsLarge }

class Review {
  final String id;
  final String productId;
  final String userName;
  final String? avatarUrl;
  final int rating;
  final String comment;
  final FitFeedback fitFeedback;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.productId,
    required this.userName,
    this.avatarUrl,
    required this.rating,
    required this.comment,
    required this.fitFeedback,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'],
        productId: json['product_id'],
        userName: json['user_name'],
        avatarUrl: json['avatar_url'],
        rating: json['rating'],
        comment: json['comment'],
        fitFeedback: _parseFit(json['fit_feedback']),
        createdAt: DateTime.parse(json['created_at']),
      );

  static FitFeedback _parseFit(String? val) {
    switch (val) {
      case 'runs_small':
        return FitFeedback.runsSmall;
      case 'runs_large':
        return FitFeedback.runsLarge;
      default:
        return FitFeedback.trueToSize;
    }
  }
}