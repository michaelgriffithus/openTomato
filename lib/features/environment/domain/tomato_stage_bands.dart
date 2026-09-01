import '../../plants/domain/enums/growth_stage.dart';

class ResolvedBand {
  final double min;
  final double max;

  const ResolvedBand({required this.min, required this.max});

  bool contains(double value) => value >= min && value <= max;

  @override
  bool operator ==(Object other) =>
      other is ResolvedBand && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(min, max);

  @override
  String toString() => 'ResolvedBand($min–$max)';
}

/// Ideal and safety bands for one stage. Ideal bands are user-overridable;
/// safety bands are app-owned and deliberately wide: a reading inside them
/// is never an emergency, and a reading outside them is a problem regardless
/// of how VPD looks.
class ResolvedStageTargetBands {
  final ResolvedBand temperatureF;
  final ResolvedBand humidityPct;
  final ResolvedBand vpdKpa;
  final ResolvedBand safetyTemperatureF;
  final ResolvedBand safetyHumidityPct;

  const ResolvedStageTargetBands({
    required this.temperatureF,
    required this.humidityPct,
    required this.vpdKpa,
    this.safetyTemperatureF = defaultSafetyTemperatureF,
    this.safetyHumidityPct = defaultSafetyHumidityPct,
  });

  static const ResolvedBand defaultSafetyTemperatureF =
      ResolvedBand(min: 50, max: 92);
  static const ResolvedBand defaultSafetyHumidityPct =
      ResolvedBand(min: 30, max: 90);

  ResolvedStageTargetBands copyWith({
    ResolvedBand? temperatureF,
    ResolvedBand? humidityPct,
    ResolvedBand? vpdKpa,
  }) {
    return ResolvedStageTargetBands(
      temperatureF: temperatureF ?? this.temperatureF,
      humidityPct: humidityPct ?? this.humidityPct,
      vpdKpa: vpdKpa ?? this.vpdKpa,
      safetyTemperatureF: safetyTemperatureF,
      safetyHumidityPct: safetyHumidityPct,
    );
  }
}

class StageTargetBandResolution {
  /// GrowthStage storage value, or [TomatoStageBands.fallbackKey].
  final String stageKey;
  final bool stageFallbackUsed;
  final ResolvedStageTargetBands bands;

  const StageTargetBandResolution({
    required this.stageKey,
    required this.stageFallbackUsed,
    required this.bands,
  });
}

/// Built-in tomato stage bands. Numbers and sources: docs/stage_targets.md.
class TomatoStageBands {
  const TomatoStageBands();

  static const String fallbackKey = 'fallback';

  /// Stage keys a grower can override, in lifecycle order, plus fallback.
  static const List<String> editableStageKeys = <String>[
    'seedling',
    'vegetative',
    'flowering',
    'fruit_set',
    'ripening',
    'harvesting',
    fallbackKey,
  ];

  static const ResolvedStageTargetBands seedling = ResolvedStageTargetBands(
    temperatureF: ResolvedBand(min: 70, max: 80),
    humidityPct: ResolvedBand(min: 60, max: 75),
    vpdKpa: ResolvedBand(min: 0.40, max: 0.80),
    safetyTemperatureF: ResolvedBand(min: 55, max: 90),
    safetyHumidityPct: ResolvedBand(min: 40, max: 90),
  );

  static const ResolvedStageTargetBands vegetative = ResolvedStageTargetBands(
    temperatureF: ResolvedBand(min: 70, max: 82),
    humidityPct: ResolvedBand(min: 55, max: 70),
    vpdKpa: ResolvedBand(min: 0.80, max: 1.20),
    safetyTemperatureF: ResolvedBand(min: 55, max: 92),
    safetyHumidityPct: ResolvedBand(min: 35, max: 90),
  );

  /// Pollen fails above roughly 90 °F by day or below about 55 °F at night.
  static const ResolvedStageTargetBands flowering = ResolvedStageTargetBands(
    temperatureF: ResolvedBand(min: 68, max: 80),
    humidityPct: ResolvedBand(min: 55, max: 70),
    vpdKpa: ResolvedBand(min: 0.80, max: 1.20),
    safetyTemperatureF: ResolvedBand(min: 55, max: 88),
    safetyHumidityPct: ResolvedBand(min: 35, max: 85),
  );

  static const ResolvedStageTargetBands fruitSet = ResolvedStageTargetBands(
    temperatureF: ResolvedBand(min: 65, max: 80),
    humidityPct: ResolvedBand(min: 50, max: 65),
    vpdKpa: ResolvedBand(min: 0.90, max: 1.30),
    safetyTemperatureF: ResolvedBand(min: 55, max: 90),
    safetyHumidityPct: ResolvedBand(min: 35, max: 85),
  );

  /// Lycopene production stalls above about 85 °F.
  static const ResolvedStageTargetBands ripening = ResolvedStageTargetBands(
    temperatureF: ResolvedBand(min: 65, max: 78),
    humidityPct: ResolvedBand(min: 50, max: 65),
    vpdKpa: ResolvedBand(min: 0.90, max: 1.30),
    safetyTemperatureF: ResolvedBand(min: 50, max: 90),
    safetyHumidityPct: ResolvedBand(min: 30, max: 85),
  );

  static const ResolvedStageTargetBands harvesting = ResolvedStageTargetBands(
    temperatureF: ResolvedBand(min: 60, max: 78),
    humidityPct: ResolvedBand(min: 45, max: 65),
    vpdKpa: ResolvedBand(min: 0.90, max: 1.40),
    safetyTemperatureF: ResolvedBand(min: 45, max: 92),
    safetyHumidityPct: ResolvedBand(min: 30, max: 85),
  );

  static const ResolvedStageTargetBands fallback = ResolvedStageTargetBands(
    temperatureF: ResolvedBand(min: 65, max: 80),
    humidityPct: ResolvedBand(min: 50, max: 70),
    vpdKpa: ResolvedBand(min: 0.80, max: 1.20),
  );

  static ResolvedStageTargetBands builtinFor(String stageKey) {
    return switch (stageKey) {
      'seedling' => seedling,
      'vegetative' => vegetative,
      'flowering' => flowering,
      'fruit_set' => fruitSet,
      'ripening' => ripening,
      'harvesting' => harvesting,
      _ => fallback,
    };
  }

  StageTargetBandResolution resolve(String? rawStage) {
    final key = normalizeStage(rawStage);
    if (key == null) {
      return const StageTargetBandResolution(
        stageKey: fallbackKey,
        stageFallbackUsed: true,
        bands: fallback,
      );
    }
    return StageTargetBandResolution(
      stageKey: key,
      stageFallbackUsed: false,
      bands: builtinFor(key),
    );
  }

  StageTargetBandResolution resolveStage(GrowthStage? stage) =>
      resolve(stage?.storageValue);

  /// Maps loose stage text to a band key. Stages with no band of their own
  /// (done, archived) resolve to null and therefore to the fallback band.
  String? normalizeStage(String? rawStage) {
    final stage = rawStage?.trim().toLowerCase().replaceAll(' ', '_');
    if (stage == null || stage.isEmpty) return null;
    return switch (stage) {
      'seedling' => 'seedling',
      'vegetative' || 'veg' => 'vegetative',
      'flowering' || 'flower' => 'flowering',
      'fruit_set' || 'fruitset' || 'fruit-set' => 'fruit_set',
      'ripening' => 'ripening',
      'harvesting' || 'harvest' => 'harvesting',
      _ => null,
    };
  }

  static String labelFor(String stageKey) {
    if (stageKey == fallbackKey) return 'No active plant';
    return GrowthStage.fromStorage(stageKey).displayName;
  }
}
