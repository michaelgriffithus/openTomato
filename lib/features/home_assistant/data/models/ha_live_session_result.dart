import 'ha_entity_state.dart';

enum HALiveSessionOutcome { live, fallback, offline }

class HALiveSessionResult {
  final HALiveSessionOutcome outcome;
  final String? baseUrl;
  final Map<String, HAEntityState> seededStates;
  final String reason;
  final bool shouldRetry;

  const HALiveSessionResult._({
    required this.outcome,
    required this.baseUrl,
    required this.seededStates,
    required this.reason,
    required this.shouldRetry,
  });

  const HALiveSessionResult.live({
    required String baseUrl,
    required Map<String, HAEntityState> seededStates,
  }) : this._(
          outcome: HALiveSessionOutcome.live,
          baseUrl: baseUrl,
          seededStates: seededStates,
          reason: '',
          shouldRetry: false,
        );

  const HALiveSessionResult.fallback({
    required String baseUrl,
    required Map<String, HAEntityState> seededStates,
    required String reason,
  }) : this._(
          outcome: HALiveSessionOutcome.fallback,
          baseUrl: baseUrl,
          seededStates: seededStates,
          reason: reason,
          shouldRetry: false,
        );

  const HALiveSessionResult.offline({
    String? baseUrl,
    required String reason,
    bool shouldRetry = true,
  }) : this._(
          outcome: HALiveSessionOutcome.offline,
          baseUrl: baseUrl,
          seededStates: const <String, HAEntityState>{},
          reason: reason,
          shouldRetry: shouldRetry,
        );

  bool get isLive => outcome == HALiveSessionOutcome.live;
  bool get isFallback => outcome == HALiveSessionOutcome.fallback;
  bool get isOffline => outcome == HALiveSessionOutcome.offline;
}
