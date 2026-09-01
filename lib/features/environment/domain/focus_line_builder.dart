import 'environment_range_evaluator.dart';

/// One plain sentence about the most important thing in the grow space.
class FocusLineBuilder {
  const FocusLineBuilder();

  static const String unconfigured = 'Connect Home Assistant to see readings.';
  static const String noReadings =
      'No readings yet. They appear once Home Assistant reports a value.';

  String build({
    required EnvironmentEvaluation? evaluation,
    required String stageLabel,
    required bool configured,
  }) {
    if (!configured) return unconfigured;
    if (evaluation == null || !evaluation.hasAnyReading) return noReadings;
    if (evaluation.allKnownInRange) {
      return 'All readings are inside the ${stageLabel.toLowerCase()} bands.';
    }
    final worst = evaluation.worst!;
    return _lineFor(worst, stageLabel);
  }

  String _lineFor(MetricStatus m, String stageLabel) {
    final value = _format(m);
    final band = '${_num(m.band.min)}–${_num(m.band.max)} ${m.metric.unit}';
    final stage = stageLabel;
    final direction = switch (m.status) {
      MetricRangeStatus.high || MetricRangeStatus.nearHigh => 'above',
      MetricRangeStatus.low || MetricRangeStatus.nearLow => 'below',
      _ => 'outside',
    };
    final lead = m.safetyBreach
        ? '${m.metric.label} $value is $direction the safe limit for $stage.'
        : m.status.isNear
            ? '${m.metric.label} $value is just $direction the $band band.'
            : '${m.metric.label} $value is $direction the $band band.';
    return '$lead ${_advice(m)}'.trim();
  }

  String _advice(MetricStatus m) {
    return switch ((m.metric, m.status)) {
      (EnvironmentMetric.temperature, MetricRangeStatus.high) ||
      (EnvironmentMetric.temperature, MetricRangeStatus.nearHigh) =>
        'Add shade or airflow, and water in the morning.',
      (EnvironmentMetric.temperature, MetricRangeStatus.low) ||
      (EnvironmentMetric.temperature, MetricRangeStatus.nearLow) =>
        'Cover plants overnight or add gentle heat.',
      (EnvironmentMetric.humidity, MetricRangeStatus.high) ||
      (EnvironmentMetric.humidity, MetricRangeStatus.nearHigh) =>
        'Improve airflow so leaves dry and pollen can shed.',
      (EnvironmentMetric.humidity, MetricRangeStatus.low) ||
      (EnvironmentMetric.humidity, MetricRangeStatus.nearLow) =>
        'Mulch and water evenly; dry air speeds up wilting.',
      (EnvironmentMetric.vpd, MetricRangeStatus.high) ||
      (EnvironmentMetric.vpd, MetricRangeStatus.nearHigh) =>
        'Air is pulling water fast: raise humidity or lower temperature.',
      (EnvironmentMetric.vpd, MetricRangeStatus.low) ||
      (EnvironmentMetric.vpd, MetricRangeStatus.nearLow) =>
        'Air is saturated: more airflow or a little warmth helps.',
      _ => '',
    };
  }

  String _format(MetricStatus m) {
    final v = m.value!;
    return switch (m.metric) {
      EnvironmentMetric.temperature => '${v.round()} °F',
      EnvironmentMetric.humidity => '${v.round()} %',
      EnvironmentMetric.vpd => '${v.toStringAsFixed(2)} kPa',
    };
  }

  String _num(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2);
}
