import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_tomato/core/database/database.dart';
import 'package:open_tomato/core/security/secure_storage.dart';
import 'package:open_tomato/features/assistant/data/ai_settings_repository.dart';
import 'package:open_tomato/features/assistant/data/assistant_service.dart';
import 'package:open_tomato/features/assistant/data/models/ai_message.dart';
import 'package:open_tomato/features/assistant/data/providers/ai_provider_client.dart';
import 'package:open_tomato/features/assistant/domain/ai_exceptions.dart';
import 'package:open_tomato/features/assistant/domain/garden_context_builder.dart';
import 'package:open_tomato/features/environment/domain/tomato_stage_bands.dart';
import 'package:open_tomato/features/plants/data/models/plant_with_variety.dart';
import 'package:open_tomato/features/plants/domain/enums/growth_stage.dart';
import 'package:open_tomato/features/plants/domain/enums/start_method.dart';
import 'package:open_tomato/features/plants/domain/models/plant_model.dart';

import '../home_assistant/fake_token_store.dart';

class FakeClient implements AiProviderClient {
  List<AiMessage>? lastMessages;
  String? lastModel;
  List<String> reply = const ['Water ', 'in the morning.'];
  Object? failWith;

  @override
  String get providerName => 'anthropic';

  @override
  Stream<String> sendMessageStreaming({
    required String apiKey,
    required String model,
    required List<AiMessage> messages,
    int maxTokens = 4096,
    String? baseUrl,
  }) async* {
    lastMessages = messages;
    lastModel = model;
    if (failWith != null) throw failWith!;
    for (final chunk in reply) {
      yield chunk;
    }
  }

  @override
  Future<String?> validateApiKey(
    String apiKey,
    String model, {
    String? baseUrl,
  }) async =>
      null;
}

void main() {
  late AppDatabase db;
  late AiSettingsRepository settings;
  late FakeClient client;
  late AssistantService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    settings = AiSettingsRepository(
      db.aiSettingsDao,
      AiApiKeyStore(FakeSecureStorage()),
    );
    client = FakeClient();
    service = AssistantService(
      settings: settings,
      dao: db.assistantDao,
      clients: {'anthropic': client},
    );
  });

  tearDown(() => db.close());

  test('no active provider throws', () async {
    expect(
      () => service.requireActive(),
      throwsA(isA<NoActiveProviderException>()),
    );
  });

  test('send assembles system, context, history, user and persists both turns',
      () async {
    await settings.save(
      provider: 'anthropic',
      modelName: 'claude-opus-5',
      apiKey: 'sk',
      makeActive: true,
      systemPromptOverride: 'Balcony in zone 7.',
    );
    final id = await service
        .startConversation('How often should I water?\nsecond line');
    expect(
      (await db.assistantDao.getConversation(id))!.title,
      'How often should I water?',
    );

    final partials = await service
        .send(
          conversationId: id,
          userText: 'How often should I water?',
          contextBlock: 'CONTEXT x',
        )
        .toList();
    expect(partials.last, 'Water in the morning.');
    expect(client.lastModel, 'claude-opus-5');
    expect(
      client.lastMessages!.map((m) => m.role).toList(),
      ['system', 'system', 'user'],
    );
    expect(client.lastMessages!.first.content, contains('Balcony in zone 7.'));
    expect(client.lastMessages![1].content, 'CONTEXT x');

    final stored = await db.assistantDao.getRecentMessages(id);
    expect(stored.map((m) => m.role).toList(), ['user', 'assistant']);
    expect(stored.first.contextBlock, 'CONTEXT x');
    expect(stored.last.model, 'claude-opus-5');

    // Second turn carries the history.
    await service
        .send(
          conversationId: id,
          userText: 'And feeding?',
          contextBlock: 'CONTEXT y',
        )
        .toList();
    expect(
      client.lastMessages!.map((m) => m.role).toList(),
      ['system', 'system', 'user', 'assistant', 'user'],
    );
  });

  test('a failed reply keeps the user message and stores no assistant turn',
      () async {
    await settings.save(
      provider: 'anthropic',
      modelName: 'm',
      apiKey: 'sk',
      makeActive: true,
    );
    client.failWith = const RateLimitException('Anthropic');
    final id = await service.startConversation('hi');
    await expectLater(
      service
          .send(conversationId: id, userText: 'hi', contextBlock: '')
          .toList(),
      throwsA(isA<RateLimitException>()),
    );
    final stored = await db.assistantDao.getRecentMessages(id);
    expect(stored.map((m) => m.role).toList(), ['user']);
  });

  test('api keys never land in the ai_settings row', () async {
    final id = await settings.save(
      provider: 'anthropic',
      modelName: 'm',
      apiKey: 'sk-secret',
      makeActive: true,
    );
    final row = await db.aiSettingsDao.getById(id);
    expect(row.toString(), isNot(contains('sk-secret')));
    expect(await settings.getApiKey(id), 'sk-secret');
    await settings.save(provider: 'anthropic', modelName: 'm2', apiKey: '');
    expect(
      await settings.getApiKey(id),
      'sk-secret',
      reason: 'empty key keeps the stored one',
    );
    expect((await db.aiSettingsDao.getById(id))!.modelName, 'm2');
  });

  test('garden context includes plants and readings but never secrets', () {
    final plant = PlantWithVariety(
      plant: PlantModel(
        id: 1,
        name: 'Sungold by the fence',
        varietyId: null,
        startDate: DateTime(2026, 7, 1),
        startMethod: StartMethod.seed,
        stage: GrowthStage.fruitSet,
        stageStartedAt: DateTime(2026, 8, 20),
        growSpaceId: null,
        location: null,
        container: null,
        medium: null,
        notes: 'token=abc',
        harvestedAt: null,
        harvestNotes: null,
        createdAt: DateTime(2026, 7, 1),
        archivedAt: null,
      ),
      variety: null,
    );
    final text = const GardenContextBuilder().build(
      GardenContextInput(
        growSpaceName: 'Greenhouse',
        stageLabel: 'Fruit set',
        bands: TomatoStageBands.fruitSet,
        reading: EnvironmentSnapshot(
          id: 1,
          growSpaceId: 'default',
          timestamp: DateTime(2026, 9, 1, 11, 50),
          tempF: 77.4,
          rhPct: 61,
          vpdKpa: 1.27,
          source: 'ha_live',
          createdAt: DateTime(2026, 9, 1),
        ),
        readingIsFresh: true,
        evaluation: null,
        vpdTimeInRange24h: null,
        plants: [plant],
        recentEntries: const [],
        openTasks: const [],
        now: DateTime(2026, 9, 1, 12),
      ),
    );
    expect(
      text,
      contains('Grow space: Greenhouse. Stage for targets: Fruit set.'),
    );
    expect(text, contains('77 °F, 61 % RH, 1.27 kPa VPD'));
    expect(
      text,
      contains('- Sungold by the fence: Unknown variety, fruit set, day 63'),
    );
    expect(text, contains('temperature 65–80 °F'));
    expect(
      text,
      isNot(contains('token=abc')),
      reason: 'plant notes are not sent',
    );
    expect(text, isNot(contains('sensor.')));
    expect(text, isNot(contains('http')));
  });
}
