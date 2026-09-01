import 'package:drift/drift.dart';

/// A physical space with its own air: a greenhouse, a shelf, a bed. Each maps
/// Home Assistant entities to the readings the app understands.
@DataClassName('GrowSpace')
class GrowSpaces extends Table {
  @override
  String get tableName => 'grow_spaces';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get tempEntityId => text().nullable()();
  TextColumn get humidityEntityId => text().nullable()();
  TextColumn get vpdEntityId => text().nullable()();
  TextColumn get soilMoistureEntityId => text().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
