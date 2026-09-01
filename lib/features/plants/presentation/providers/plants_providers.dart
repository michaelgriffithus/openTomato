import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../data/models/plant_with_variety.dart';
import '../../data/repositories/plants_repository.dart';

final activePlantsProvider = StreamProvider<List<PlantWithVariety>>((ref) {
  return ref.watch(plantsRepositoryProvider).watchActivePlants();
});

final growActivePlantsProvider = StreamProvider<List<PlantWithVariety>>((ref) {
  return ref.watch(plantsRepositoryProvider).watchGrowActivePlants();
});

final archivedPlantsProvider = StreamProvider<List<PlantWithVariety>>((ref) {
  return ref.watch(plantsRepositoryProvider).watchArchivedPlants();
});

final plantByIdProvider =
    StreamProvider.family<PlantWithVariety?, int>((ref, id) {
  return ref.watch(plantsRepositoryProvider).watchPlantById(id);
});

final plantStageHistoryProvider =
    StreamProvider.family<List<PlantStageHistory>, int>((ref, id) {
  return ref.watch(plantsRepositoryProvider).watchStageHistory(id);
});
