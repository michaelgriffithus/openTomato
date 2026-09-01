import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../../../core/utils/plant_age.dart';
import '../../../home_assistant/presentation/providers/grow_spaces_providers.dart';
import '../../../journal/presentation/providers/journal_providers.dart';
import '../../data/models/plant_with_variety.dart';
import '../../domain/enums/growth_stage.dart';
import '../providers/plants_providers.dart';

enum PlantsScreenPhase { loading, ready, empty, error }

class PlantRowContract {
  final int id;
  final String name;
  final String varietyLabel;
  final String ageLabel;
  final GrowthStage stage;
  final String? thumbnailPath;

  const PlantRowContract({
    required this.id,
    required this.name,
    required this.varietyLabel,
    required this.ageLabel,
    required this.stage,
    required this.thumbnailPath,
  });
}

class PlantGroupContract {
  final String growSpaceName;
  final List<PlantRowContract> plants;

  const PlantGroupContract({required this.growSpaceName, required this.plants});
}

class PlantsScreenContract {
  final PlantsScreenPhase phase;
  final int activeCount;
  final List<PlantGroupContract> groups;
  final List<PlantRowContract> archivedPlants;
  final String? errorMessage;

  const PlantsScreenContract({
    required this.phase,
    required this.activeCount,
    required this.groups,
    required this.archivedPlants,
    this.errorMessage,
  });

  static const loading = PlantsScreenContract(
    phase: PlantsScreenPhase.loading,
    activeCount: 0,
    groups: [],
    archivedPlants: [],
  );
}

final plantsScreenContractProvider = Provider<PlantsScreenContract>((ref) {
  final plants = ref.watch(activePlantsProvider);
  final archived = ref.watch(archivedPlantsProvider);
  final entries = ref.watch(allJournalEntriesProvider);
  final growSpaces = ref.watch(growSpacesStreamProvider);

  if (plants.hasError) {
    return PlantsScreenContract(
      phase: PlantsScreenPhase.error,
      activeCount: 0,
      groups: const [],
      archivedPlants: const [],
      errorMessage: 'Could not load plants: ${plants.error}',
    );
  }
  if (plants.isLoading && !plants.hasValue) return PlantsScreenContract.loading;

  return buildPlantsScreenContract(
    active: plants.valueOrNull ?? const [],
    archived: archived.valueOrNull ?? const [],
    entries: entries.valueOrNull ?? const [],
    growSpaces: growSpaces.valueOrNull ?? const [],
  );
});

/// Pure mapping so it can be tested without a provider scope.
PlantsScreenContract buildPlantsScreenContract({
  required List<PlantWithVariety> active,
  required List<PlantWithVariety> archived,
  required List<JournalEntryWithPlantsAndPhotosEntity> entries,
  required List<GrowSpace> growSpaces,
  DateTime? now,
}) {
  final thumbnails = latestThumbnailsByPlant(entries);
  final spaceNames = {for (final space in growSpaces) space.id: space.name};
  final defaultName = spaceNames[kDefaultGrowSpaceId] ?? 'My grow space';

  final grouped = <String, List<PlantRowContract>>{};
  for (final plant in active) {
    final spaceId = plant.plant.growSpaceId ?? kDefaultGrowSpaceId;
    final name = spaceNames[spaceId] ?? defaultName;
    (grouped[name] ??= []).add(_row(plant, thumbnails[plant.plant.id], now));
  }
  final groups = [
    for (final entry in grouped.entries)
      PlantGroupContract(growSpaceName: entry.key, plants: entry.value),
  ]..sort(
      (a, b) => a.growSpaceName == defaultName
          ? -1
          : b.growSpaceName == defaultName
              ? 1
              : a.growSpaceName.compareTo(b.growSpaceName),
    );

  final archivedRows = [
    for (final plant in archived) _row(plant, thumbnails[plant.plant.id], now),
  ];

  return PlantsScreenContract(
    phase: active.isEmpty && archived.isEmpty
        ? PlantsScreenPhase.empty
        : PlantsScreenPhase.ready,
    activeCount: active.length,
    groups: groups,
    archivedPlants: archivedRows,
  );
}

PlantRowContract _row(PlantWithVariety p, String? thumbnail, DateTime? now) {
  return PlantRowContract(
    id: p.plant.id,
    name: p.plant.name,
    varietyLabel: p.varietyLabel,
    ageLabel: plantAgeLabel(p.plant.startDate, now: now),
    stage: p.plant.stage,
    thumbnailPath: thumbnail,
  );
}

String plantAgeLabel(DateTime startDate, {DateTime? now}) {
  final days = plantAge(startDate: startDate, now: now).days;
  if (days == null) return 'Starts soon';
  if (days == 0) return 'Started today';
  if (days < 14) return 'Day $days';
  final weeks = days ~/ 7;
  final rest = days % 7;
  return rest == 0 ? '$weeks weeks' : '$weeks weeks, $rest days';
}

/// Newest photo thumbnail per plant, walking entries newest-first.
Map<int, String> latestThumbnailsByPlant(
  List<JournalEntryWithPlantsAndPhotosEntity> entries,
) {
  final result = <int, String>{};
  for (final entry in entries) {
    if (entry.photos.isEmpty) continue;
    for (final plant in entry.plants) {
      result.putIfAbsent(plant.id, () => entry.photos.first.thumbnailPath);
    }
  }
  return result;
}
