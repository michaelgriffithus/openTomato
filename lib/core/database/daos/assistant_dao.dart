import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/assistant_conversations.dart';
import '../tables/assistant_messages.dart';

part 'assistant_dao.g.dart';

@DriftAccessor(tables: [AssistantConversations, AssistantMessages])
class AssistantDao extends DatabaseAccessor<AppDatabase>
    with _$AssistantDaoMixin {
  AssistantDao(super.db);

  Stream<List<AssistantConversation>> watchConversations() {
    return (select(assistantConversations)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<AssistantConversation?> getConversation(int id) {
    return (select(assistantConversations)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> createConversation(String title) {
    return into(assistantConversations).insert(
      AssistantConversationsCompanion.insert(title: title),
    );
  }

  Future<void> renameConversation(int id, String title) async {
    await (update(assistantConversations)..where((t) => t.id.equals(id))).write(
      AssistantConversationsCompanion(
        title: Value(title),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> touchConversation(int id) async {
    await (update(assistantConversations)..where((t) => t.id.equals(id))).write(
      AssistantConversationsCompanion(updatedAt: Value(DateTime.now())),
    );
  }

  /// Cascade deletes the conversation's messages.
  Future<int> deleteConversation(int id) {
    return (delete(assistantConversations)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<AssistantMessage>> watchMessages(int conversationId) {
    return (select(assistantMessages)
          ..where((t) => t.conversationId.equals(conversationId))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .watch();
  }

  /// Newest [limit] messages in chronological order.
  Future<List<AssistantMessage>> getRecentMessages(
    int conversationId, {
    int limit = 20,
  }) async {
    final rows = await (select(assistantMessages)
          ..where((t) => t.conversationId.equals(conversationId))
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(limit))
        .get();
    return rows.reversed.toList(growable: false);
  }

  Future<int> insertMessage(AssistantMessagesCompanion companion) {
    return into(assistantMessages).insert(companion);
  }

  Future<void> updateMessageContent(
    int id, {
    required String content,
    int? inputTokens,
    int? outputTokens,
  }) async {
    await (update(assistantMessages)..where((t) => t.id.equals(id))).write(
      AssistantMessagesCompanion(
        content: Value(content),
        inputTokens: Value(inputTokens),
        outputTokens: Value(outputTokens),
      ),
    );
  }

  Future<int> deleteMessage(int id) {
    return (delete(assistantMessages)..where((t) => t.id.equals(id))).go();
  }
}
