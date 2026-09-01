import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../data/repositories/varieties_repository.dart';

final varietiesRepositoryProvider = Provider<VarietiesRepository>((ref) {
  return VarietiesRepository(ref.watch(varietiesDaoProvider));
});

final allVarietiesProvider = StreamProvider<List<Variety>>((ref) {
  return ref.watch(varietiesRepositoryProvider).watchAll();
});

final varietySearchProvider =
    StreamProvider.family<List<Variety>, String>((ref, query) {
  return ref.watch(varietiesRepositoryProvider).search(query);
});
