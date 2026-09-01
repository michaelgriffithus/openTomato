import '../../domain/exceptions/ha_exceptions.dart';
import '../models/ha_entity_state.dart';
import '../models/ha_live_update_models.dart';
import '../repositories/grow_spaces_repository.dart';
import '../repositories/ha_settings_repository.dart';
import 'ha_client.dart';
import 'ha_endpoint_resolver.dart';
import 'ha_reading_normalizer.dart';

/// Facade for one-shot REST work: test a connection, read a grow space's
/// current values, validate an entity id.
class HAService {
  final HASettingsRepository _settings;
  final GrowSpacesRepository _growSpaces;
  final HARestClient _client;
  final HAEndpointResolver _endpoint;
  final HAReadingNormalizer _normalizer;

  const HAService({
    required HASettingsRepository settings,
    required GrowSpacesRepository growSpaces,
    required HARestClient client,
    required HAEndpointResolver endpoint,
    HAReadingNormalizer normalizer = const HAReadingNormalizer(),
  })  : _settings = settings,
        _growSpaces = growSpaces,
        _client = client,
        _endpoint = endpoint,
        _normalizer = normalizer;

  /// Tests arbitrary credentials (used by the settings form before saving).
  Future<bool> testConnection(String baseUrl, String accessToken) async {
    final ok = await _client.testConnection(baseUrl, accessToken);
    if (ok) await _settings.updateLastSuccessfulConnection(DateTime.now());
    return ok;
  }

  Future<bool> isConfigured() => _settings.isConfigured;

  /// Current values for one grow space, in canonical units.
  Future<HALiveReading> fetchReadingForGrowSpace(String growSpaceId) async {
    final mappings = await _growSpaces.getMappings(growSpaceId);
    if (mappings.isEmpty) return HALiveReading.empty;
    final baseUrl = await _endpoint.resolveBaseUrl();
    final token = await _endpoint.resolveAccessToken();
    final states = await _client.fetchMultipleEntities(
      baseUrl,
      token,
      mappings.values.toSet().toList(growable: false),
    );
    return readingFromStates(mappings, states);
  }

  /// Current values for every enabled grow space. Spaces that fail are
  /// skipped so one bad mapping never blocks the others.
  Future<Map<String, HALiveReading>> fetchAllReadings() async {
    final result = <String, HALiveReading>{};
    for (final space in await _growSpaces.getEnabledGrowSpaces()) {
      try {
        final reading = await fetchReadingForGrowSpace(space.id);
        if (reading.hasUsableValues) result[space.id] = reading;
      } on HAException {
        // Skip this space; the caller reports on what it got.
      }
    }
    if (result.isNotEmpty) {
      await _settings.updateLastSuccessfulConnection(DateTime.now());
    }
    return result;
  }

  HALiveReading readingFromStates(
    Map<String, String> fieldToEntity,
    Map<String, HAEntityState> states,
  ) {
    HAEntityState? stateFor(String field) {
      final id = fieldToEntity[field];
      return id == null ? null : states[id];
    }

    final tempF =
        _normalizer.temperatureF(stateFor(HAReadingNormalizer.temperature));
    final humidity =
        _normalizer.humidityPct(stateFor(HAReadingNormalizer.humidity));
    final upstreamVpd = _normalizer.vpdKpa(stateFor(HAReadingNormalizer.vpd));
    return HALiveReading(
      tempF: tempF,
      humidityPct: humidity,
      vpdKpa: _normalizer.canonicalVpd(
        tempF: tempF,
        humidityPct: humidity,
        upstreamVpdKpa: upstreamVpd,
      ),
      soilMoisturePct: _normalizer
          .soilMoisturePct(stateFor(HAReadingNormalizer.soilMoisture)),
    );
  }

  Future<bool> validateEntityId(String entityId) async {
    try {
      final baseUrl = await _endpoint.resolveBaseUrl();
      final token = await _endpoint.resolveAccessToken();
      await _client.fetchEntityState(baseUrl, token, entityId);
      return true;
    } on HAException {
      return false;
    }
  }
}
