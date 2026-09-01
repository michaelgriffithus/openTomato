import 'package:flutter_test/flutter_test.dart';
import 'package:open_tomato/features/environment/domain/environment_range_evaluator.dart';
import 'package:open_tomato/features/environment/domain/tomato_stage_bands.dart';

void main() {
  const evaluator = EnvironmentRangeEvaluator();
  final bands = TomatoStageBands.vegetative; // 70–82 °F, 55–70 %, 0.8–1.2

  EnvironmentEvaluation eval({double? t, double? rh, double? vpd}) =>
      evaluator.evaluate(tempF: t, rhPct: rh, vpdKpa: vpd, bands: bands);

  test('all inside → inRange, nothing worst beyond inRange', () {
    final e = eval(t: 75, rh: 60, vpd: 1.0);
    expect(e.temperature.status, MetricRangeStatus.inRange);
    expect(e.humidity.status, MetricRangeStatus.inRange);
    expect(e.vpd.status, MetricRangeStatus.inRange);
    expect(e.allKnownInRange, isTrue);
    expect(e.worst!.status, MetricRangeStatus.inRange);
  });

  test('band edges are inclusive', () {
    final e = eval(t: 70, rh: 70, vpd: 1.2);
    expect(e.temperature.status, MetricRangeStatus.inRange);
    expect(e.humidity.status, MetricRangeStatus.inRange);
    expect(e.vpd.status, MetricRangeStatus.inRange);
  });

  test('just outside within tolerance → near', () {
    expect(eval(t: 83.5).temperature.status, MetricRangeStatus.nearHigh);
    expect(eval(t: 68.5).temperature.status, MetricRangeStatus.nearLow);
    expect(eval(rh: 74).humidity.status, MetricRangeStatus.nearHigh);
    expect(eval(rh: 51).humidity.status, MetricRangeStatus.nearLow);
    expect(eval(vpd: 1.3).vpd.status, MetricRangeStatus.nearHigh);
    expect(eval(vpd: 0.7).vpd.status, MetricRangeStatus.nearLow);
  });

  test('beyond tolerance → low/high', () {
    expect(eval(t: 85).temperature.status, MetricRangeStatus.high);
    expect(eval(t: 67).temperature.status, MetricRangeStatus.low);
    expect(eval(rh: 76).humidity.status, MetricRangeStatus.high);
    expect(eval(rh: 40).humidity.status, MetricRangeStatus.low);
    expect(eval(vpd: 1.5).vpd.status, MetricRangeStatus.high);
    expect(eval(vpd: 0.5).vpd.status, MetricRangeStatus.low);
  });

  test('missing or non-finite values are unknown, never a problem', () {
    final e = eval(t: double.nan);
    expect(e.temperature.status, MetricRangeStatus.unknown);
    expect(e.temperature.safetyBreach, isFalse);
    expect(e.hasAnyReading, isFalse);
    expect(e.worst, isNull);
    expect(e.allKnownInRange, isFalse);
  });

  test('safety breach only outside the safety band', () {
    expect(eval(t: 85).temperature.safetyBreach, isFalse); // safe max 92
    expect(eval(t: 95).temperature.safetyBreach, isTrue);
    expect(eval(t: 50).temperature.safetyBreach, isTrue); // safe min 55
    expect(eval(rh: 20).humidity.safetyBreach, isTrue); // safe min 35
    expect(eval(vpd: 3).vpd.safetyBreach, isFalse); // no VPD safety band
  });

  test('worst prefers safety breach over out-of-range over near', () {
    final e = eval(t: 95, rh: 76, vpd: 1.3);
    expect(e.worst!.metric, EnvironmentMetric.temperature);
    final f = eval(t: 75, rh: 76, vpd: 1.3);
    expect(f.worst!.metric, EnvironmentMetric.humidity);
    final g = eval(t: 75, rh: 60, vpd: 1.3);
    expect(g.worst!.metric, EnvironmentMetric.vpd);
  });

  test('custom tolerances are honoured', () {
    const wide = EnvironmentRangeEvaluator(nearTemperatureF: 10);
    final e = wide.evaluate(tempF: 90, rhPct: null, vpdKpa: null, bands: bands);
    expect(e.temperature.status, MetricRangeStatus.nearHigh);
  });
}
