import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lookbook.dart';
import '../data/mock_repository.dart';

final lookbookProvider = FutureProvider<List<Lookbook>>((ref) async {
  return MockRepository.getLookbooks();
});
