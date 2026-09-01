import 'dart:async';

import 'package:drift/drift.dart';

import '../../../core/database/database.dart';
import '../domain/ai_exceptions.dart';
import '../domain/assistant_system_prompt.dart';
import 'ai_settings_repository.dart';
import 'models/ai_message.dart';
import 'providers/ai_provider_client.dart';

/// Assembles `[system][context][history][user]`, streams the reply, and
/// persists both sides of the turn.
class AssistantService {
  final AiSettingsRepository _settings;
  final AssistantDao _dao;
  final Map<String, AiProviderClient> _clients;

  /// Older messages are dropped from the request, not from storage.
  static const int historyLimit = 20;

  const AssistantService({
    required AiSettingsRepository settings,
    required AssistantDao dao,
    required Map<String, AiProviderClient> clients,
  })  : _settings = settings,
        _dao = dao,
        _clients = clients;

  Future<AiSetting> requireActive() async {
    final active = await _settings.getActive();
    if (active == null) throw const NoActiveProviderException();
    return active;
  }

  Future<int> startConversation(String firstMessage) {
    final title = firstMessage.trim().split('\n').first;
    return _dao.createConversation(
      title.length > 60 ? '${title.substring(0, 59)}…' : title,
    );
  }

  /// Sends [userText] in [conversationId]. Yields the growing assistant
  /// reply. The user message and the final reply are stored; on failure the
  /// user message stays so the grower can retry.
  Stream<String> send({
    required int conversationId,
    required String userText,
    required String contextBlock,
  }) async* {
    final setting = await requireActive();
    final client = _clients[setting.provider];
    if (client == null) {
      throw ApiErrorException('Unknown provider ${setting.provider}');
    }
    final apiKey = await _settings.getApiKey(setting.id);
    if (apiKey == null || apiKey.isEmpty) {
      throw InvalidApiKeyException(setting.provider);
    }

    final history =
        await _dao.getRecentMessages(conversationId, limit: historyLimit);
    await _dao.insertMessage(
      AssistantMessagesCompanion.insert(
        conversationId: conversationId,
        role: 'user',
        content: userText.trim(),
        contextBlock: Value(contextBlock),
      ),
    );

    final messages = <AiMessage>[
      AiMessage.system(
        buildSystemPrompt(override: setting.systemPromptOverride),
      ),
      AiMessage.system(contextBlock),
      for (final m in history) AiMessage(role: m.role, content: m.content),
      AiMessage.user(userText.trim()),
    ];

    final reply = StringBuffer();
    await for (final chunk in client.sendMessageStreaming(
      apiKey: apiKey,
      model: setting.modelName,
      messages: messages,
      maxTokens: setting.maxOutputTokens,
      baseUrl: setting.baseUrl,
    )) {
      reply.write(chunk);
      yield reply.toString();
    }
    final text = reply.toString().trim();
    if (text.isNotEmpty) {
      await _dao.insertMessage(
        AssistantMessagesCompanion.insert(
          conversationId: conversationId,
          role: 'assistant',
          content: text,
          provider: Value(setting.provider),
          model: Value(setting.modelName),
        ),
      );
    }
    await _dao.touchConversation(conversationId);
  }
}
