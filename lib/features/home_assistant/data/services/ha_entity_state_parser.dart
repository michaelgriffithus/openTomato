import '../models/ha_entity_state.dart';

class HAParsedStateChange {
  final String entityId;
  final HAEntityState nextState;

  const HAParsedStateChange({required this.entityId, required this.nextState});
}

class HAEntityStateParser {
  const HAEntityStateParser();

  HAParsedStateChange? parseStateChangedEvent(Map<String, dynamic> event) {
    if (event['type'] != 'event') return null;
    final payload = event['event'];
    if (payload is! Map<String, dynamic> ||
        payload['event_type'] != 'state_changed') {
      return null;
    }
    final data = payload['data'];
    if (data is! Map<String, dynamic>) return null;
    final entityId = data['entity_id']?.toString().trim();
    if (entityId == null || entityId.isEmpty) return null;
    final newStateRaw = data['new_state'];
    if (newStateRaw is! Map<String, dynamic>) return null;
    return HAParsedStateChange(
      entityId: entityId,
      nextState: HAEntityState.fromJson(newStateRaw),
    );
  }
}
