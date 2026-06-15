import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review.dart';
import '../data/mock_repository.dart';

final reviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, productId) async {
  return MockRepository.getReviews(productId: productId);
});
