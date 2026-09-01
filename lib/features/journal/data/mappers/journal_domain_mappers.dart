import '../../../../core/database/database.dart';
import '../../../plants/data/mappers/plant_domain_mappers.dart';
import '../../domain/enums/entry_type.dart';
import '../models/journal_entry_with_details.dart';

extension JournalEntryEntityToDomain on JournalEntry {
  JournalEntryModel toDomain() {
    return JournalEntryModel(
      id: id,
      timestamp: timestamp,
      content: content,
      type: EntryType.fromStorage(entryType),
      tempF: tempF,
      humidityPct: humidityPct,
      vpdKpa: vpdKpa,
      soilMoisturePct: soilMoisturePct,
      watered: watered,
      nutrients: nutrients,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension JournalPhotoEntityToDomain on JournalPhoto {
  JournalPhotoModel toDomain() {
    return JournalPhotoModel(
      id: id,
      journalEntryId: journalEntryId,
      filePath: filePath,
      thumbnailPath: thumbnailPath,
      displayOrder: displayOrder,
      createdAt: createdAt,
    );
  }
}

extension JournalEntryWithPlantsAndPhotosEntityToDomain
    on JournalEntryWithPlantsAndPhotosEntity {
  JournalEntryWithPlantsAndPhotos toDomain() {
    return JournalEntryWithPlantsAndPhotos(
      entry: entry.toDomain(),
      photos: photos.map((photo) => photo.toDomain()).toList(growable: false),
      plants: plants.map((plant) => plant.toDomain()).toList(growable: false),
    );
  }
}

extension JournalNutrientRowEntityToDomain on JournalNutrientRow {
  NutrientLineItemModel toDomain() {
    return NutrientLineItemModel(productName: productName, amount: amount);
  }
}

extension JournalEntryDetailsEntityToDomain on JournalEntryDetailsEntity {
  JournalEntryDetails toDomain() {
    return JournalEntryDetails(
      entry: entry.toDomain(),
      photos: photos.map((photo) => photo.toDomain()).toList(growable: false),
      plants: plants.map((plant) => plant.toDomain()).toList(growable: false),
      nutrientRows:
          nutrientRows.map((row) => row.toDomain()).toList(growable: false),
    );
  }
}
