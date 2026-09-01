class HADiscoveredEntity {
  final String entityId;
  final String state;
  final String? friendlyName;
  final String? deviceClass;
  final String? unit;
  final Map<String, dynamic> attributes;

  const HADiscoveredEntity({
    required this.entityId,
    required this.state,
    required this.friendlyName,
    required this.deviceClass,
    required this.unit,
    this.attributes = const {},
  });

  String get searchText =>
      '${friendlyName ?? ''} $entityId ${unit ?? ''} ${deviceClass ?? ''}'
          .toLowerCase();

  String get displayLabel {
    final name = (friendlyName == null || friendlyName!.trim().isEmpty)
        ? entityId
        : friendlyName!.trim();
    if (unit != null && unit!.isNotEmpty) return '$name ($unit)';
    return name;
  }

  bool get isUsable {
    final normalized = state.trim().toLowerCase();
    return normalized.isNotEmpty &&
        normalized != 'unknown' &&
        normalized != 'unavailable';
  }
}
