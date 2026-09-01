import 'package:drift/drift.dart';

import 'plants.dart';

@DataClassName('PlantStageHistory')
class PlantStageHistoryTable extends Table {
  @override
  String get tableName => 'plant_stage_history';

  IntColumn get plantId =>
      integer().references(Plants, #id, onDelete: KeyAction.cascade)();

  /// GrowthStage storage value.
  TextColumn get stage => text()();
  DateTimeColumn get movedAt => dateTime()();
  IntColumn get expectedDurationDays => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {plantId, stage};
}
