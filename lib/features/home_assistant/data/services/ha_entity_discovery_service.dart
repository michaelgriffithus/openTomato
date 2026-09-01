import '../models/ha_discovered_entity.dart';
import 'ha_client.dart';
import 'ha_endpoint_resolver.dart';

/// Lists sensors from `/api/states` and filters them per slot. Throws
/// (rather than returning an empty list) when Home Assistant is not
/// configured, so a configuration problem never looks like "no sensors".
class HAEntityDiscoveryService {
  final HAEndpointResolver _endpoint;
  final HARestClient _client;

  const HAEntityDiscoveryService({
    required HAEndpointResolver endpoint,
    required HARestClient client,
  })  : _endpoint = endpoint,
        _client = client;

  Future<List<HADiscoveredEntity>> discover() async {
    final baseUrl = await _endpoint.resolveBaseUrl();
    final token = await _endpoint.resolveAccessToken();
    return _client.fetchAllEntities(baseUrl, token);
  }

  List<HADiscoveredEntity> candidatesForTemperature(
    List<HADiscoveredEntity> entities,
  ) {
    return entities.where((e) {
      final deviceClass = (e.deviceClass ?? '').toLowerCase();
      final unit = (e.unit ?? '').toLowerCase();
      final id = e.entityId.toLowerCase();
      if (!_isSensor(id)) return false;
      return deviceClass == 'temperature' ||
          unit == '°f' ||
          unit == '°c' ||
          id.contains('temp');
    }).toList(growable: false);
  }

  List<HADiscoveredEntity> candidatesForHumidity(
    List<HADiscoveredEntity> entities,
  ) {
    return entities.where((e) {
      final deviceClass = (e.deviceClass ?? '').toLowerCase();
      final unit = (e.unit ?? '').toLowerCase();
      final id = e.entityId.toLowerCase();
      if (!_isSensor(id)) return false;
      return deviceClass == 'humidity' ||
          (unit == '%' && !id.contains('moist') && !id.contains('battery')) ||
          id.contains('humid') ||
          id.endsWith('_rh');
    }).toList(growable: false);
  }

  List<HADiscoveredEntity> candidatesForVpd(List<HADiscoveredEntity> entities) {
    return entities.where((e) {
      final unit = (e.unit ?? '').toLowerCase();
      final id = e.entityId.toLowerCase();
      if (!_isSensor(id)) return false;
      return unit == 'kpa' || unit == 'psi' || id.contains('vpd');
    }).toList(growable: false);
  }

  List<HADiscoveredEntity> candidatesForSoilMoisture(
    List<HADiscoveredEntity> entities,
  ) {
    return entities.where((e) {
      final deviceClass = (e.deviceClass ?? '').toLowerCase();
      final id = e.entityId.toLowerCase();
      final name = (e.friendlyName ?? '').toLowerCase();
      if (!_isSensor(id)) return false;
      return deviceClass == 'moisture' ||
          id.contains('moist') ||
          name.contains('moisture');
    }).toList(growable: false);
  }

  /// Entity ids that look like something other than air in a grow space.
  static bool looksSuspiciousForAir(String entityId) {
    final id = entityId.toLowerCase();
    return RegExp(r'cpu|processor|disk|battery|gpu|ssd|nvme|fridge|freezer')
        .hasMatch(id);
  }

  bool _isSensor(String entityId) => entityId.startsWith('sensor.');
}
