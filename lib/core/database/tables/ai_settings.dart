import 'package:drift/drift.dart';

/// Assistant provider configuration. API keys are NOT stored here; they live
/// in secure storage keyed by this row's id (see AiApiKeyStore).
@DataClassName('AiSetting')
class AiSettings extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// anthropic or openai.
  TextColumn get provider => text()();
  TextColumn get modelName => text()();

  /// Optional OpenAI-compatible base URL override.
  TextColumn get baseUrl => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  IntColumn get maxOutputTokens =>
      integer().withDefault(const Constant(4096))();
  TextColumn get systemPromptOverride => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
