import 'package:flutter_test/flutter_test.dart';
import 'package:open_tomato/features/environment/domain/environment_range_evaluator.dart';
import 'package:open_tomato/features/environment/domain/focus_line_builder.dart';
import 'package:open_tomato/features/environment/domain/tomato_stage_bands.dart';

void main() {
  const builder = FocusLineBuilder();
  const evaluator = EnvironmentRangeEvaluator();
  final bands = TomatoStageBands.flowering; // 68–80, 55–70, 0.8–1.2

  EnvironmentEvaluation eval({double? t, double? rh, double? vpd}) =>
      evaluator.evaluate(tempF: t, rhPct: rh, vpdKpa: vpd, bands: bands);

  test('unconfigured wins over everything', () {
    expect(
      builder.build(
        evaluation: eval(t: 99),
        stageLabel: 'Flowering',
        configured: false,
      ),
      FocusLineBuilder.unconfigured,
    );
  });

  test('no readings', () {
    expect(
      builder.build(
        evaluation: eval(),
        stageLabel: 'Flowering',
        configured: true,
      ),
      FocusLineBuilder.noReadings,
    );
    expect(
      builder.build(
        evaluation: null,
        stageLabel: 'Flowering',
        configured: true,
      ),
      FocusLineBuilder.noReadings,
    );
  });

  test('all in range names the stage', () {
    expect(
      builder.build(
        evaluation: eval(t: 75, rh: 60, vpd: 1.0),
        stageLabel: 'Flowering',
        configured: true,
      ),
      'All readings are inside the flowering bands.',
    );
  });

  test('humidity high in flowering mentions airflow and the band', () {
    final line = builder.build(
      evaluation: eval(t: 75, rh: 78, vpd: 1.0),
      stageLabel: 'Flowering',
      configured: true,
    );
    expect(line, contains('Humidity 78 % is above the 55–70 % band.'));
    expect(line, contains('airflow'));
  });

  test('near uses "just"', () {
    final line = builder.build(
      evaluation: eval(t: 81, rh: 60, vpd: 1.0),
      stageLabel: 'Flowering',
      configured: true,
    );
    expect(
      line,
      startsWith('Temperature 81 °F is just above the 68–80 °F band.'),
    );
  });

  test('safety breach names the safe limit', () {
    final line = builder.build(
      evaluation: eval(t: 95, rh: 60, vpd: 1.0),
      stageLabel: 'Flowering',
      configured: true,
    );
    expect(
      line,
      startsWith('Temperature 95 °F is above the safe limit for Flowering.'),
    );
  });

  test('VPD low advice', () {
    final line = builder.build(
      evaluation: eval(t: 75, rh: 60, vpd: 0.5),
      stageLabel: 'Flowering',
      configured: true,
    );
    expect(line, contains('VPD 0.50 kPa is below the 0.80–1.20 kPa band.'));
    expect(line, contains('saturated'));
  });
}
