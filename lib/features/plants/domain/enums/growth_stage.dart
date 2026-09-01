import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Tomato growth stages. [storageValue] is what the database stores; never
/// rename a storage value once shipped.
enum GrowthStage {
  seedling('seedling', 'Seedling'),
  vegetative('vegetative', 'Vegetative'),
  flowering('flowering', 'Flowering'),
  fruitSet('fruit_set', 'Fruit set'),
  ripening('ripening', 'Ripening'),
  harvesting('harvesting', 'Harvesting'),
  done('done', 'Done'),
  archived('archived', 'Archived');

  const GrowthStage(this.storageValue, this.displayName);

  final String storageValue;
  final String displayName;

  /// Stages during which the plant is alive and in a grow space.
  bool get isGrowActive => this != done && this != archived;

  /// Stages a grower can move a plant into from the stage picker.
  static List<GrowthStage> get selectable =>
      values.where((s) => s != archived).toList(growable: false);

  Color get color => switch (this) {
        GrowthStage.seedling => AppColors.stageSeedling,
        GrowthStage.vegetative => AppColors.stageVegetative,
        GrowthStage.flowering => AppColors.stageFlowering,
        GrowthStage.fruitSet => AppColors.stageFruitSet,
        GrowthStage.ripening => AppColors.stageRipening,
        GrowthStage.harvesting => AppColors.stageHarvesting,
        GrowthStage.done => AppColors.stageDone,
        GrowthStage.archived => AppColors.stageArchived,
      };

  /// Short guidance shown beside the stage name.
  String get description => switch (this) {
        GrowthStage.seedling => 'From emergence until the first true leaves.',
        GrowthStage.vegetative => 'Leaves and stems; before the first flowers.',
        GrowthStage.flowering => 'First flower clusters open.',
        GrowthStage.fruitSet => 'Small green fruit forming on the trusses.',
        GrowthStage.ripening => 'Fruit sizing and colouring.',
        GrowthStage.harvesting => 'Picking ripe fruit.',
        GrowthStage.done => 'The plant has finished.',
        GrowthStage.archived => 'Hidden from the active list.',
      };

  static GrowthStage fromStorage(String? value) {
    if (value == null) return GrowthStage.seedling;
    for (final stage in values) {
      if (stage.storageValue == value || stage.name == value) return stage;
    }
    return GrowthStage.seedling;
  }
}
