import '../../../plants/domain/models/plant_model.dart';
import '../../domain/enums/entry_type.dart';

class JournalEntryModel {
  final int id;
  final DateTime timestamp;
  final String? content;
  final EntryType type;
  final double? tempF;
  final double? humidityPct;
  final double? vpdKpa;
  final double? soilMoisturePct;
  final bool watered;
  final String? nutrients;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JournalEntryModel({
    required this.id,
    required this.timestamp,
    required this.content,
    required this.type,
    required this.tempF,
    required this.humidityPct,
    required this.vpdKpa,
    required this.soilMoisturePct,
    required this.watered,
    required this.nutrients,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasReadings =>
      tempF != null ||
      humidityPct != null ||
      vpdKpa != null ||
      soilMoisturePct != null;
}

class JournalPhotoModel {
  final int id;
  final int journalEntryId;
  final String filePath;
  final String thumbnailPath;
  final int displayOrder;
  final DateTime createdAt;

  const JournalPhotoModel({
    required this.id,
    required this.journalEntryId,
    required this.filePath,
    required this.thumbnailPath,
    required this.displayOrder,
    required this.createdAt,
  });
}

/// A single product line, e.g. "Tomato feed" / "10 ml".
class NutrientLineItemModel {
  final String productName;
  final String? amount;

  const NutrientLineItemModel({required this.productName, this.amount});
}

class JournalEntryWithPlantsAndPhotos {
  final JournalEntryModel entry;
  final List<JournalPhotoModel> photos;
  final List<PlantModel> plants;

  const JournalEntryWithPlantsAndPhotos({
    required this.entry,
    required this.photos,
    required this.plants,
  });
}

class JournalEntryDetails {
  final JournalEntryModel entry;
  final List<JournalPhotoModel> photos;
  final List<PlantModel> plants;
  final List<NutrientLineItemModel> nutrientRows;

  const JournalEntryDetails({
    required this.entry,
    required this.photos,
    required this.plants,
    this.nutrientRows = const <NutrientLineItemModel>[],
  });
}
