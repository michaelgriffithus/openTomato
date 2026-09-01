import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../../home_assistant/presentation/providers/grow_spaces_providers.dart';
import '../../../journal/domain/enums/entry_type.dart';
import '../../../journal/presentation/providers/journal_providers.dart';
import '../../data/models/plant_with_variety.dart';
import '../../domain/enums/growth_stage.dart';
import '../../domain/services/stage_progress.dart';
import '../providers/plants_providers.dart';
import '../widgets/plant_lifecycle_timeline.dart';

enum PlantDetailPhase { loading, ready, missing }

class PlantDetailEntryContract {
  final int id;
  final String title;
  final String dateLabel;
  final EntryType type;
  final String? thumbnailPath;

  const PlantDetailEntryContract({
    required this.id,
    required this.title,
    required this.dateLabel,
    required this.type,
    required this.thumbnailPath,
  });
}

class PlantDetailContract {
  final PlantDetailPhase phase;
  final int plantId;
  final String name;
  final String varietyLabel;
  final String growSpaceLabel;
  final GrowthStage stage;
  final String ageLabel;
  final String stageDayLabel;
  final String? maturityLabel;
  final String? detailsLine;
  final String? notes;
  final DateTime? harvestedAt;
  final String? harvestNotes;
  final bool isArchived;
  final String? heroImagePath;
  final List<PlantLifecycleStage> lifecycle;
  final List<PlantDetailEntryContract> recentEntries;
  final int photoCount;

  const PlantDetailContract({
    required this.phase,
    required this.plantId,
    required this.name,
    required this.varietyLabel,
    required this.growSpaceLabel,
    required this.stage,
    required this.ageLabel,
    required this.stageDayLabel,
    required this.maturityLabel,
    required this.detailsLine,
    required this.notes,
    required this.harvestedAt,
    required this.harvestNotes,
    required this.isArchived,
    required this.heroImagePath,
    required this.lifecycle,
    required this.recentEntries,
    required this.photoCount,
  });

  factory PlantDetailContract.placeholder(int plantId, PlantDetailPhase phase) {
    return PlantDetailContract(
      phase: phase,
      plantId: plantId,
      name: '',
      varietyLabel: '',
      growSpaceLabel: '',
      stage: GrowthStage.seedling,
      ageLabel: '',
      stageDayLabel: '',
      maturityLabel: null,
      detailsLine: null,
      notes: null,
      harvestedAt: null,
      harvestNotes: null,
      isArchived: false,
      heroImagePath: null,
      lifecycle: const [],
      recentEntries: const [],
      photoCount: 0,
    );
  }
}

final plantDetailContractProvider =
    Provider.family<PlantDetailContract, int>((ref, plantId) {
  final plant = ref.watch(plantByIdProvider(plantId));
  final history = ref.watch(plantStageHistoryProvider(plantId));
  final entries = ref.watch(plantJournalEntriesProvider(plantId));
  final growSpaces = ref.watch(growSpacesStreamProvider);

  if (plant.isLoading && !plant.hasValue) {
    return PlantDetailContract.placeholder(plantId, PlantDetailPhase.loading);
  }
  final value = plant.valueOrNull;
  if (value == null) {
    return PlantDetailContract.placeholder(plantId, PlantDetailPhase.missing);
  }
  return buildPlantDetailContract(
    plant: value,
    history: history.valueOrNull ?? const [],
    entries: entries.valueOrNull ?? const [],
    growSpaces: growSpaces.valueOrNull ?? const [],
  );
});

PlantDetailContract buildPlantDetailContract({
  required PlantWithVariety plant,
  required List<PlantStageHistory> history,
  required List<JournalEntryWithPlantsAndPhotosEntity> entries,
  required List<GrowSpace> growSpaces,
  DateTime? now,
}) {
  final p = plant.plant;
  final progress = stageProgress(
    startDate: p.startDate,
    stageStartedAt: p.stageStartedAt,
    daysToMaturity: plant.variety?.daysToMaturity,
    now: now,
  );
  final movedAt = {
    for (final row in history) GrowthStage.fromStorage(row.stage): row.movedAt,
  };
  final spaceId = p.growSpaceId ?? kDefaultGrowSpaceId;
  final space = growSpaces.where((s) => s.id == spaceId).firstOrNull;

  String? hero;
  var photoCount = 0;
  for (final entry in entries) {
    photoCount += entry.photos.length;
    hero ??= entry.photos.isEmpty ? null : entry.photos.first.filePath;
  }

  final details = [
    if (p.location != null) p.location!,
    if (p.container != null) p.container!,
    if (p.medium != null) p.medium!,
    p.startMethod.displayName,
  ].join(' · ');

  final dtm = progress.daysToExpectedMaturity;
  final maturity = dtm == null
      ? null
      : dtm > 0
          ? 'About $dtm days to maturity'
          : 'Past the expected maturity date';

  return PlantDetailContract(
    phase: PlantDetailPhase.ready,
    plantId: p.id,
    name: p.name,
    varietyLabel: plant.varietyLabel,
    growSpaceLabel: space?.name ?? 'Default grow space',
    stage: p.stage,
    ageLabel: _ageLabel(progress.daysSinceStart),
    stageDayLabel: progress.daysInStage == null
        ? p.stage.displayName
        : '${p.stage.displayName} · day ${progress.daysInStage! + 1}',
    maturityLabel: maturity,
    detailsLine: details.isEmpty ? null : details,
    notes: p.notes,
    harvestedAt: p.harvestedAt,
    harvestNotes: p.harvestNotes,
    isArchived: p.isArchived,
    heroImagePath: hero,
    lifecycle: buildLifecycleStages(current: p.stage, movedAt: movedAt),
    recentEntries: [
      for (final entry in entries.take(5))
        PlantDetailEntryContract(
          id: entry.entry.id,
          title: _entryTitle(entry),
          dateLabel: _shortDate(entry.entry.timestamp),
          type: EntryType.fromStorage(entry.entry.entryType),
          thumbnailPath:
              entry.photos.isEmpty ? null : entry.photos.first.thumbnailPath,
        ),
    ],
    photoCount: photoCount,
  );
}

String _ageLabel(int? days) {
  if (days == null) return 'Start date not set';
  if (days == 0) return 'Started today';
  return 'Day ${days + 1} since start';
}

String _entryTitle(JournalEntryWithPlantsAndPhotosEntity entry) {
  final content = entry.entry.content?.trim();
  if (content != null && content.isNotEmpty) {
    final firstLine = content.split('\n').first;
    return firstLine.length > 80 ? '${firstLine.substring(0, 77)}…' : firstLine;
  }
  return EntryType.fromStorage(entry.entry.entryType).displayName;
}

String _shortDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}
