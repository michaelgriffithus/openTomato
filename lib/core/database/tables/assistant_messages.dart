import 'package:drift/drift.dart';

import 'assistant_conversations.dart';

@DataClassName('AssistantMessage')
class AssistantMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId => integer().references(
        AssistantConversations,
        #id,
        onDelete: KeyAction.cascade,
      )();

  /// user or assistant.
  TextColumn get role => text()();
  TextColumn get content => text()();

  /// The context block that was sent with a user message, so the grower can
  /// see exactly what left the device.
  TextColumn get contextBlock => text().nullable()();
  TextColumn get provider => text().nullable()();
  TextColumn get model => text().nullable()();
  IntColumn get inputTokens => integer().nullable()();
  IntColumn get outputTokens => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
