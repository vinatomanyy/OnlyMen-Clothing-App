import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lookbook.dart';
import '../data/supabase_repository.dart';

final lookbookProvider = FutureProvider<List<Lookbook>>((ref) async {
  return SupabaseRepository.getLookbooks();
});