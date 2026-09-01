import '../../domain/models/plant_model.dart';
import '../../domain/models/variety_model.dart';

class PlantWithVariety {
  final PlantModel plant;
  final VarietyModel? variety;

  const PlantWithVariety({required this.plant, required this.variety});

  String get varietyLabel => variety?.name ?? 'Unknown variety';
}
