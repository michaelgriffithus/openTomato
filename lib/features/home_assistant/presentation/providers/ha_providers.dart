import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/security/secure_storage.dart';
import '../../data/models/ha_live_update_models.dart';
import '../../data/repositories/grow_spaces_repository.dart';
import '../../data/repositories/ha_settings_repository.dart';
import '../../data/services/ha_client.dart';
import '../../data/services/ha_endpoint_resolver.dart';
import '../../data/services/ha_entity_discovery_service.dart';
import '../../data/services/ha_entity_state_parser.dart';
import '../../data/services/ha_environment_sync_service.dart';
import '../../data/services/ha_history_backfill_service.dart';
import '../../data/services/ha_history_service.dart';
import '../../data/services/ha_live_session_coordinator.dart';
import '../../data/services/ha_live_update_service.dart';
import '../../data/services/ha_polling_service.dart';
import '../../data/services/ha_service.dart';
import '../../data/services/ha_websocket_client.dart';
import '../../data/services/ha_websocket_manager.dart';

final secureKeyValueStoreProvider = Provider<SecureKeyValueStore>((ref) {
  return const FlutterSecureKeyValueStore();
});

/// Private: the token never enters the public provider graph.
final _haAccessTokenStoreProvider = Provider<HaAccessTokenStore>((ref) {
  return HaAccessTokenStore(ref.watch(secureKeyValueStoreProvider));
});

final haSettingsRepositoryProvider = Provider<HASettingsRepository>((ref) {
  return HASettingsRepository(
    dao: ref.watch(haSettingsDaoProvider),
    tokenStore: ref.watch(_haAccessTokenStoreProvider),
  );
});

final growSpacesRepositoryProvider = Provider<GrowSpacesRepository>((ref) {
  return GrowSpacesRepository(ref.watch(growSpacesDaoProvider));
});

final haClientProvider = Provider<HAClient>((ref) => const HAClient());

final haEndpointResolverProvider = Provider<HAEndpointResolver>((ref) {
  return HAEndpointResolver(ref.watch(haSettingsRepositoryProvider));
});

/// Keep this graph stable: do not watch the settings stream here, or a
/// metadata write (lastSuccessfulConnection) recreates the socket and
/// triggers bootstrap loops.
final haWebSocketClientProvider = Provider<HAWebSocketClient>((ref) {
  final client = HAWebSocketClient();
  ref.onDispose(client.dispose);
  return client;
});

final haWebSocketManagerProvider = Provider<HAWebSocketManager>((ref) {
  final manager = HAWebSocketManager(
    webSocketClient: ref.watch(haWebSocketClientProvider),
  );
  ref.onDispose(manager.dispose);
  return manager;
});

final haEntityStateParserProvider =
    Provider<HAEntityStateParser>((ref) => const HAEntityStateParser());

final haServiceProvider = Provider<HAService>((ref) {
  return HAService(
    settings: ref.watch(haSettingsRepositoryProvider),
    growSpaces: ref.watch(growSpacesRepositoryProvider),
    client: ref.watch(haClientProvider),
    endpoint: ref.watch(haEndpointResolverProvider),
  );
});

final haEntityDiscoveryServiceProvider =
    Provider<HAEntityDiscoveryService>((ref) {
  return HAEntityDiscoveryService(
    endpoint: ref.watch(haEndpointResolverProvider),
    client: ref.watch(haClientProvider),
  );
});

final haEnvironmentSyncServiceProvider =
    Provider<HaEnvironmentSyncService>((ref) {
  return HaEnvironmentSyncService(
    snapshots: ref.watch(environmentSnapshotsDaoProvider),
  );
});

final haHistoryServiceProvider = Provider<HaHistoryService>((ref) {
  return HaHistoryService(
    endpoint: ref.watch(haEndpointResolverProvider),
    restClient: ref.watch(haClientProvider),
  );
});

final haHistoryBackfillServiceProvider =
    Provider<HaHistoryBackfillService>((ref) {
  return HaHistoryBackfillService(
    snapshots: ref.watch(environmentSnapshotsDaoProvider),
    settings: ref.watch(haSettingsRepositoryProvider),
    growSpaces: ref.watch(growSpacesRepositoryProvider),
    sync: ref.watch(haEnvironmentSyncServiceProvider),
    historyService: ref.watch(haHistoryServiceProvider),
  );
});

final haPollingServiceProvider = Provider<HaPollingService>((ref) {
  final service = HaPollingService(
    settings: ref.watch(haSettingsRepositoryProvider),
    haService: ref.watch(haServiceProvider),
    sync: ref.watch(haEnvironmentSyncServiceProvider),
  )..start();
  ref.onDispose(service.stop);
  return service;
});

final haLiveSessionCoordinatorProvider =
    Provider<HALiveSessionCoordinator>((ref) {
  final coordinator = HALiveSessionCoordinator(
    endpoint: ref.watch(haEndpointResolverProvider),
    webSocketManager: ref.watch(haWebSocketManagerProvider),
    restClient: ref.watch(haClientProvider),
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

final haLiveUpdateServiceProvider =
    StateNotifierProvider<HALiveUpdateService, HALiveTelemetrySnapshot>((ref) {
  return HALiveUpdateService(
    settings: ref.watch(haSettingsRepositoryProvider),
    growSpaces: ref.watch(growSpacesRepositoryProvider),
    webSocketManager: ref.watch(haWebSocketManagerProvider),
    parser: ref.watch(haEntityStateParserProvider),
    sync: ref.watch(haEnvironmentSyncServiceProvider),
    coordinator: ref.watch(haLiveSessionCoordinatorProvider),
  );
});

final haSettingsStreamProvider = StreamProvider<HomeAssistantSetting?>((ref) {
  return ref.watch(haSettingsRepositoryProvider).watchSettings();
});

final haIsConfiguredProvider = FutureProvider<bool>((ref) {
  ref.watch(haSettingsStreamProvider);
  return ref.watch(haSettingsRepositoryProvider).isConfigured;
});
