import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/branch.dart';
import '../data/mock_repository.dart';

final branchesProvider = FutureProvider<List<Branch>>((ref) async {
  return MockRepository.getBranches();
});
