import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../../../core/providers/database_provider.dart';

final growSpacesStreamProvider = StreamProvider<List<GrowSpace>>((ref) {
  return ref.watch(growSpacesDaoProvider).watchAllGrowSpaces();
});

final growSpaceByIdProvider =
    StreamProvider.family<GrowSpace?, String>((ref, id) {
  return ref.watch(growSpacesDaoProvider).watchGrowSpaceById(id);
});

final growSpaceStageTargetsProvider =
    FutureProvider.family<List<GrowSpaceStageTarget>, String>((ref, id) {
  ref.watch(growSpacesStreamProvider);
  return ref.watch(growSpacesDaoProvider).getStageTargetsForGrowSpace(id);
});
