import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/promotion.dart';
import '../data/mock_repository.dart';

final promotionsProvider = FutureProvider<List<Promotion>>((ref) async {
  return MockRepository.getPromotions();
});
