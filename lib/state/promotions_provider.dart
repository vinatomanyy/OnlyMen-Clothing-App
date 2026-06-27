import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/promotion.dart';
import '../data/supabase_repository.dart';

final promotionsProvider = FutureProvider.autoDispose<List<Promotion>>((ref) async {
  return SupabaseRepository.getPromotions();
});
