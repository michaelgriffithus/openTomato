import '../database.dart';

class JournalEntryWithPlantsAndPhotosEntity {
  final JournalEntry entry;
  final List<JournalPhoto> photos;
  final List<Plant> plants;
  const JournalEntryWithPlantsAndPhotosEntity({
    required this.entry,
    required this.photos,
    required this.plants,
  });
}

class JournalEntryDetailsEntity {
  final JournalEntry entry;
  final List<JournalPhoto> photos;
  final List<Plant> plants;
  final List<JournalNutrientRow> nutrientRows;
  const JournalEntryDetailsEntity({
    required this.entry,
    required this.photos,
    required this.plants,
    required this.nutrientRows,
  });
}
