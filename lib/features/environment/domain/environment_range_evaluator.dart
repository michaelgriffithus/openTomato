import 'tomato_stage_bands.dart';

enum MetricRangeStatus {
  inRange,
  nearLow,
  nearHigh,
  low,
  high,
  unknown;

  bool get isOutOfRange => this == low || this == high;
  bool get isNear => this == nearLow || this == nearHigh;

  /// Higher is worse.
  int get severity => switch (this) {
        MetricRangeStatus.unknown => 0,
        MetricRangeStatus.inRange => 1,
        MetricRangeStatus.nearLow || MetricRangeStatus.nearHigh => 2,
        MetricRangeStatus.low || MetricRangeStatus.high => 3,
      };
}

enum EnvironmentMetric {
  temperature('Temperature', '°F'),
  humidity('Humidity', '%'),
  vpd('VPD', 'kPa');

  const EnvironmentMetric(this.label, this.unit);

  final String label;
  final String unit;
}

class MetricStatus {
  final EnvironmentMetric metric;
  final double? value;
  final ResolvedBand band;
  final MetricRangeStatus status;

  /// True when the value is outside the app-owned safety band (temperature
  /// and humidity only; VPD has no safety band).
  final bool safetyBreach;

  const MetricStatus({
    required this.metric,
    required this.value,
    required this.band,
    required this.status,
    required this.safetyBreach,
  });

  /// Safety breaches outrank everything, then out-of-range, near, in range,
  /// and finally unknown (no data is not a problem to shout about).
  int get severity => safetyBreach ? 4 : status.severity;
}

class EnvironmentEvaluation {
  final MetricStatus temperature;
  final MetricStatus humidity;
  final MetricStatus vpd;

  const EnvironmentEvaluation({
    required this.temperature,
    required this.humidity,
    required this.vpd,
  });

  List<MetricStatus> get metrics => [temperature, humidity, vpd];

  /// The metric most in need of attention, or null when nothing is known.
  MetricStatus? get worst {
    MetricStatus? result;
    for (final metric in metrics) {
      if (metric.status == MetricRangeStatus.unknown) continue;
      if (result == null || metric.severity > result.severity) {
        result = metric;
      }
    }
    return result;
  }

  bool get hasAnyReading =>
      metrics.any((m) => m.status != MetricRangeStatus.unknown);

  bool get allKnownInRange =>
      hasAnyReading &&
      metrics.every(
        (m) =>
            m.status == MetricRangeStatus.unknown ||
            m.status == MetricRangeStatus.inRange,
      );
}

/// Pure classification of a reading against a stage's bands.
class EnvironmentRangeEvaluator {
  const EnvironmentRangeEvaluator({
    this.nearTemperatureF = 2.0,
    this.nearHumidityPct = 5.0,
    this.nearVpdKpa = 0.15,
  });

  /// How far outside the ideal band still counts as "near".
  final double nearTemperatureF;
  final double nearHumidityPct;
  final double nearVpdKpa;

  EnvironmentEvaluation evaluate({
    required double? tempF,
    required double? rhPct,
    required double? vpdKpa,
    required ResolvedStageTargetBands bands,
  }) {
    return EnvironmentEvaluation(
      temperature: _classify(
        EnvironmentMetric.temperature,
        tempF,
        bands.temperatureF,
        nearTemperatureF,
        safety: bands.safetyTemperatureF,
      ),
      humidity: _classify(
        EnvironmentMetric.humidity,
        rhPct,
        bands.humidityPct,
        nearHumidityPct,
        safety: bands.safetyHumidityPct,
      ),
      vpd: _classify(EnvironmentMetric.vpd, vpdKpa, bands.vpdKpa, nearVpdKpa),
    );
  }

  MetricStatus _classify(
    EnvironmentMetric metric,
    double? value,
    ResolvedBand band,
    double tolerance, {
    ResolvedBand? safety,
  }) {
    if (value == null || !value.isFinite) {
      return MetricStatus(
        metric: metric,
        value: null,
        band: band,
        status: MetricRangeStatus.unknown,
        safetyBreach: false,
      );
    }
    final status = switch (value) {
      _ when value < band.min - tolerance => MetricRangeStatus.low,
      _ when value < band.min => MetricRangeStatus.nearLow,
      _ when value > band.max + tolerance => MetricRangeStatus.high,
      _ when value > band.max => MetricRangeStatus.nearHigh,
      _ => MetricRangeStatus.inRange,
    };
    return MetricStatus(
      metric: metric,
      value: value,
      band: band,
      status: status,
      safetyBreach: safety != null && !safety.contains(value),
    );
  }
}
