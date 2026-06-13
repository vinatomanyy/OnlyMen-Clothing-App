import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/branch.dart';
import '../data/supabase_repository.dart';

final branchesProvider = FutureProvider<List<Branch>>((ref) async {
  return SupabaseRepository.getBranches();
});