import 'package:drift/drift.dart';

/// Tomato varieties (built-in seed list plus user-created ones).
@DataClassName('Variety')
class Varieties extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100).unique()();

  /// GrowthHabit storage value: determinate, indeterminate,
  /// semi_determinate, dwarf.
  TextColumn get growthHabit => text()();

  /// VarietyCategory storage value: cherry, grape, paste, slicer, beefsteak,
  /// heirloom.
  TextColumn get category => text()();
  IntColumn get daysToMaturity => integer().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get userCreated => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
