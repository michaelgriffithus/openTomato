import 'package:drift/drift.dart';

/// Per-grow-space overrides of the built-in stage bands. A metric's override
/// only wins when both its min and max are set.
@DataClassName('GrowSpaceStageTarget')
class GrowSpaceStageTargets extends Table {
  @override
  String get tableName => 'grow_space_stage_targets';

  TextColumn get growSpaceId => text()();

  /// GrowthStage storage value or 'fallback'.
  TextColumn get stageKey => text()();
  RealColumn get tempMinF => real().nullable()();
  RealColumn get tempMaxF => real().nullable()();
  RealColumn get humidityMinPct => real().nullable()();
  RealColumn get humidityMaxPct => real().nullable()();
  RealColumn get vpdMinKpa => real().nullable()();
  RealColumn get vpdMaxKpa => real().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {growSpaceId, stageKey};
}
