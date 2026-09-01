import '../models/ha_entity_state.dart';
import '../models/ha_live_update_models.dart';
import '../repositories/grow_spaces_repository.dart';
import 'ha_reading_normalizer.dart';

class EntityRoute {
  final String growSpaceId;
  final String fieldKey;

  const EntityRoute({required this.growSpaceId, required this.fieldKey});
}

/// Maps entity ids to the grow-space slots that use them, and keeps the
/// latest state per slot so a reading can be rebuilt after each change.
class HALiveRouting {
  final HAReadingNormalizer _normalizer;
  final Map<String, List<EntityRoute>> _routesByEntityId = {};
  final Map<String, Map<String, HAEntityState>> _statesByGrowSpace = {};

  HALiveRouting({HAReadingNormalizer normalizer = const HAReadingNormalizer()})
      : _normalizer = normalizer;

  Iterable<String> get entityIds => _routesByEntityId.keys;
  bool get isEmpty => _routesByEntityId.isEmpty;

  Set<String> get growSpaceIds => _routesByEntityId.values
      .expand((routes) => routes.map((r) => r.growSpaceId))
      .toSet();

  List<EntityRoute> routesFor(String entityId) =>
      _routesByEntityId[entityId] ?? const [];

  Future<void> rebuild(GrowSpacesRepository growSpaces) async {
    _routesByEntityId.clear();
    _statesByGrowSpace.clear();
    for (final space in await growSpaces.getEnabledGrowSpaces()) {
      final mappings = await growSpaces.getMappings(space.id);
      mappings.forEach((fieldKey, entityId) {
        _routesByEntityId
            .putIfAbsent(entityId, () => [])
            .add(EntityRoute(growSpaceId: space.id, fieldKey: fieldKey));
      });
    }
  }

  /// Records a state and returns the grow spaces it belongs to.
  Set<String> apply(String entityId, HAEntityState state) {
    final touched = <String>{};
    for (final route in routesFor(entityId)) {
      _statesByGrowSpace.putIfAbsent(
        route.growSpaceId,
        () => {},
      )[route.fieldKey] = state;
      touched.add(route.growSpaceId);
    }
    return touched;
  }

  HALiveReading readingFor(String growSpaceId) {
    final fields = _statesByGrowSpace[growSpaceId];
    if (fields == null || fields.isEmpty) return HALiveReading.empty;
    final tempF =
        _normalizer.temperatureF(fields[HAReadingNormalizer.temperature]);
    final humidity =
        _normalizer.humidityPct(fields[HAReadingNormalizer.humidity]);
    final upstreamVpd = _normalizer.vpdKpa(fields[HAReadingNormalizer.vpd]);
    return HALiveReading(
      tempF: tempF,
      humidityPct: humidity,
      vpdKpa: _normalizer.canonicalVpd(
        tempF: tempF,
        humidityPct: humidity,
        upstreamVpdKpa: upstreamVpd,
      ),
      soilMoisturePct:
          _normalizer.soilMoisturePct(fields[HAReadingNormalizer.soilMoisture]),
    );
  }

  /// True when any grow space would have a usable reading from [states].
  bool hasUsableStates(Map<String, HAEntityState> states) {
    final scratch = HALiveRouting(normalizer: _normalizer)
      .._routesByEntityId.addAll(_routesByEntityId);
    for (final entry in states.entries) {
      for (final id in scratch.apply(entry.key, entry.value)) {
        if (scratch.readingFor(id).hasUsableValues) return true;
      }
    }
    return false;
  }
}
