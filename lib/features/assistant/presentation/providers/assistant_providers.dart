import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/security/secure_storage.dart';
import '../../../environment/domain/tomato_stage_bands.dart';
import '../../../environment/presentation/providers/environment_providers.dart';
import '../../../home_assistant/presentation/providers/grow_spaces_providers.dart';
import '../../../home_assistant/presentation/providers/ha_providers.dart';
import '../../../journal/presentation/providers/journal_providers.dart';
import '../../../plants/presentation/providers/plants_providers.dart';
import '../../../todos/presentation/providers/todo_providers.dart';
import '../../data/ai_settings_repository.dart';
import '../../data/assistant_service.dart';
import '../../data/providers/ai_provider_client.dart';
import '../../data/providers/anthropic_client.dart';
import '../../data/providers/openai_client.dart';
import '../../domain/cloud_provider_consent.dart';
import '../../domain/garden_context_builder.dart';

final aiApiKeyStoreProvider = Provider<AiApiKeyStore>((ref) {
  return AiApiKeyStore(ref.watch(secureKeyValueStoreProvider));
});

final aiSettingsRepositoryProvider = Provider<AiSettingsRepository>((ref) {
  return AiSettingsRepository(
    ref.watch(aiSettingsDaoProvider),
    ref.watch(aiApiKeyStoreProvider),
  );
});

final allAiSettingsProvider = StreamProvider<List<AiSetting>>((ref) {
  return ref.watch(aiSettingsRepositoryProvider).watchAll();
});

final activeAiSettingProvider = StreamProvider<AiSetting?>((ref) {
  return ref.watch(aiSettingsRepositoryProvider).watchActive();
});

final aiProviderClientsProvider =
    Provider<Map<String, AiProviderClient>>((ref) {
  return {
    'anthropic': AnthropicClient(),
    'openai': OpenAiClient(),
  };
});

final assistantServiceProvider = Provider<AssistantService>((ref) {
  return AssistantService(
    settings: ref.watch(aiSettingsRepositoryProvider),
    dao: ref.watch(assistantDaoProvider),
    clients: ref.watch(aiProviderClientsProvider),
  );
});

final assistantConversationsProvider =
    StreamProvider<List<AssistantConversation>>((ref) {
  return ref.watch(assistantDaoProvider).watchConversations();
});

final assistantMessagesProvider =
    StreamProvider.family<List<AssistantMessage>, int>((ref, conversationId) {
  return ref.watch(assistantDaoProvider).watchMessages(conversationId);
});

/// Whether the grower has accepted the disclaimer and the active provider's
/// consent. Re-evaluated whenever app settings change.
final assistantGatesProvider =
    FutureProvider<({bool disclaimer, bool consent})>((ref) async {
  final settings = ref.watch(appSettingsDaoProvider);
  final active = await ref.watch(activeAiSettingProvider.future);
  final disclaimer = await settings.getBool(CloudProviderConsent.disclaimerKey);
  final consent = active == null
      ? false
      : await CloudProviderConsent.isAccepted(settings, active.provider);
  return (disclaimer: disclaimer, consent: consent);
});

/// The context block for the grow space currently shown on Today.
final gardenContextProvider = Provider<String>((ref) {
  final growSpaceId = ref.watch(effectiveGrowSpaceIdProvider);
  final spaces = ref.watch(growSpacesStreamProvider).valueOrNull ?? const [];
  final space = spaces.where((s) => s.id == growSpaceId).firstOrNull;
  final stage = ref.watch(growSpaceStageProvider(growSpaceId));
  final bands = ref.watch(stageBandsProvider(growSpaceId)).valueOrNull;
  final latest = ref.watch(latestSnapshotProvider(growSpaceId)).valueOrNull;
  final fresh = ref.watch(currentReadingProvider(growSpaceId));
  final evaluation = ref.watch(environmentEvaluationProvider(growSpaceId));
  final tir = ref.watch(
    timeInRangeProvider(
      (growSpaceId: growSpaceId, window: ReadingWindow.day),
    ),
  );
  final plants = ref.watch(growActivePlantsProvider).valueOrNull ?? const [];
  final entries =
      ref.watch(journalTimelineEntriesProvider).valueOrNull ?? const [];
  final tasks = ref.watch(activeTodosProvider).valueOrNull ?? const [];
  return const GardenContextBuilder().build(
    GardenContextInput(
      growSpaceName: space?.name ?? 'My grow space',
      stageLabel: stage?.displayName ??
          TomatoStageBands.labelFor(TomatoStageBands.fallbackKey),
      bands: bands?.bands,
      reading: latest,
      readingIsFresh: fresh != null,
      evaluation: evaluation,
      vpdTimeInRange24h: tir?.vpd,
      plants: plants,
      recentEntries: entries.take(5).toList(),
      openTasks: [for (final t in tasks) t.todo],
      now: DateTime.now(),
    ),
  );
});
