class HAEntityState {
  final String entityId;
  final String state;
  final Map<String, dynamic> attributes;
  final DateTime lastChanged;
  final DateTime? lastUpdated;

  const HAEntityState({
    required this.entityId,
    required this.state,
    required this.attributes,
    required this.lastChanged,
    this.lastUpdated,
  });

  factory HAEntityState.fromJson(Map<String, dynamic> json) {
    final rawAttributes = json['attributes'];
    return HAEntityState(
      entityId: (json['entity_id'] ?? '') as String,
      state: (json['state'] ?? '') as String,
      attributes: rawAttributes is Map<String, dynamic>
          ? rawAttributes
          : <String, dynamic>{},
      lastChanged: DateTime.tryParse((json['last_changed'] ?? '') as String) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      lastUpdated: DateTime.tryParse((json['last_updated'] ?? '') as String),
    );
  }

  String? get unit => attributes['unit_of_measurement']?.toString();

  double? get numericState => double.tryParse(state.trim());
}
