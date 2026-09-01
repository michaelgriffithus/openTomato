import 'package:drift/drift.dart';

@DataClassName('HomeAssistantSetting')
class HomeAssistantSettings extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// `http(s)://host[:port]`, no trailing slash. The access token is NOT here;
  /// it lives in secure storage (see HaAccessTokenStore).
  TextColumn get baseUrl => text().nullable()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get pollIntervalMinutes =>
      integer().withDefault(const Constant(15))();
  IntColumn get liveWarnThresholdMinutes =>
      integer().withDefault(const Constant(5))();
  IntColumn get liveStaleThresholdMinutes =>
      integer().withDefault(const Constant(15))();

  /// Informational only. Never gate behaviour on this: a device that lives
  /// purely on the live WebSocket path never records one.
  DateTimeColumn get lastSuccessfulConnection => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
