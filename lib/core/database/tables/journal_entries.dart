import 'package:drift/drift.dart';

@DataClassName('JournalEntry')
class JournalEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get content => text().nullable()();

  /// EntryType storage value.
  TextColumn get entryType => text().withDefault(const Constant('note'))();

  // Readings captured with the entry (manual or "use current reading").
  RealColumn get tempF => real().nullable()();
  RealColumn get humidityPct => real().nullable()();
  RealColumn get vpdKpa => real().nullable()();
  RealColumn get soilMoisturePct => real().nullable()();

  BoolColumn get watered => boolean().withDefault(const Constant(false))();
  TextColumn get nutrients => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
