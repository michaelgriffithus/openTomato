import 'package:drift/drift.dart';

/// One reading of a grow space's air, recorded from Home Assistant.
@DataClassName('EnvironmentSnapshot')
class EnvironmentSnapshots extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get growSpaceId => text()();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get tempF => real().nullable()();
  RealColumn get rhPct => real().nullable()();

  /// Always the canonical Tetens result from tempF and rhPct.
  RealColumn get vpdKpa => real().nullable()();

  /// VPD as reported by the mapped entity, kept as provenance only.
  RealColumn get upstreamVpdKpa => real().nullable()();
  RealColumn get soilMoisturePct => real().nullable()();

  /// ha_live, ha_poll, or ha_backfill.
  TextColumn get source => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {growSpaceId, timestamp},
      ];
}
