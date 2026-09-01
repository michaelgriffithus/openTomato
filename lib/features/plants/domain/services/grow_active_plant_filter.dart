import '../enums/growth_stage.dart';

/// Storage values of stages that are NOT grow-active. Shared by the DAO
/// (SQL `NOT IN`) and Dart-side filters so the two never disagree.
final List<String> kExcludedGrowActiveStageNames = GrowthStage.values
    .where((stage) => !stage.isGrowActive)
    .map((stage) => stage.storageValue)
    .toList(growable: false);

bool isGrowActiveStage(GrowthStage stage) => stage.isGrowActive;
