import 'package:drift/drift.dart';

import 'varieties.dart';

@DataClassName('Plant')
class Plants extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get varietyId => integer()
      .nullable()
      .references(Varieties, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get startDate => dateTime()();

  /// StartMethod storage value: seed, transplant, cutting.
  TextColumn get startMethod => text().withDefault(const Constant('seed'))();

  /// GrowthStage storage value.
  TextColumn get currentStage => text()();
  DateTimeColumn get stageStartedAt => dateTime().nullable()();

  /// Grow space whose sensors describe this plant's air. Null means the
  /// default grow space.
  TextColumn get growSpaceId => text().nullable()();

  /// indoor, greenhouse, outdoor (free text label).
  TextColumn get location => text().nullable()();
  TextColumn get container => text().nullable()();
  TextColumn get medium => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get harvestedAt => dateTime().nullable()();
  TextColumn get harvestNotes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get archivedAt => dateTime().nullable()();
}
