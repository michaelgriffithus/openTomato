import '../../../../core/database/database.dart';
import '../../../varieties/domain/enums/growth_habit.dart';
import '../../../varieties/domain/enums/variety_category.dart';
import '../../domain/enums/growth_stage.dart';
import '../../domain/enums/start_method.dart';
import '../../domain/models/plant_model.dart';
import '../../domain/models/variety_model.dart';
import '../models/plant_with_variety.dart';

extension PlantEntityToDomain on Plant {
  PlantModel toDomain() {
    return PlantModel(
      id: id,
      name: name,
      varietyId: varietyId,
      startDate: startDate,
      startMethod: StartMethod.fromStorage(startMethod),
      stage: GrowthStage.fromStorage(currentStage),
      stageStartedAt: stageStartedAt,
      growSpaceId: growSpaceId,
      location: location,
      container: container,
      medium: medium,
      notes: notes,
      harvestedAt: harvestedAt,
      harvestNotes: harvestNotes,
      createdAt: createdAt,
      archivedAt: archivedAt,
    );
  }
}

extension VarietyEntityToDomain on Variety {
  VarietyModel toDomain() {
    return VarietyModel(
      id: id,
      name: name,
      habit: GrowthHabit.fromStorage(growthHabit),
      category: VarietyCategory.fromStorage(category),
      daysToMaturity: daysToMaturity,
      notes: notes,
      userCreated: userCreated,
    );
  }
}

extension PlantWithVarietyEntityToDomain on PlantWithVarietyEntity {
  PlantWithVariety toDomain() {
    return PlantWithVariety(
      plant: plant.toDomain(),
      variety: variety?.toDomain(),
    );
  }
}
