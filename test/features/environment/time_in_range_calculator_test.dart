import 'package:flutter_test/flutter_test.dart';
import 'package:open_tomato/features/environment/domain/time_in_range_calculator.dart';
import 'package:open_tomato/features/environment/domain/tomato_stage_bands.dart';

void main() {
  const calc = TimeInRangeCalculator();
  const band = ResolvedBand(min: 60, max: 80);
  final start = DateTime.utc(2026, 9, 1, 0, 0);
  final end = start.add(const Duration(hours: 24));

  TimedSample at(int minutes, double v) =>
      TimedSample(start.add(Duration(minutes: minutes)), v);

  test('empty samples → empty result with the window recorded', () {
    final r = calc.compute(
      samples: const [],
      band: band,
      windowStart: start,
      windowEnd: end,
    );
    expect(r.pct, isNull);
    expect(r.coveredFraction, 0);
    expect(r.coverageSufficient, isFalse);
    expect(r.window, const Duration(hours: 24));
  });

  test('inverted window → empty', () {
    final r = calc.compute(
      samples: [at(0, 70)],
      band: band,
      windowStart: end,
      windowEnd: start,
    );
    expect(r, same(TimeInRangeResult.empty));
  });

  test('samples every 5 minutes, all in range → 100 % with full coverage', () {
    final samples = [for (var m = 0; m < 24 * 60; m += 5) at(m, 70.0)];
    final r = calc.compute(
      samples: samples,
      band: band,
      windowStart: start,
      windowEnd: end,
    );
    expect(r.pct, closeTo(100, 0.001));
    expect(r.coveredFraction, closeTo(1, 0.001));
    expect(r.coverageSufficient, isTrue);
  });

  test('half the samples out of range → 50 %', () {
    final samples = [
      for (var m = 0; m < 24 * 60; m += 5) at(m, m < 12 * 60 ? 70.0 : 90.0),
    ];
    final r = calc.compute(
      samples: samples,
      band: band,
      windowStart: start,
      windowEnd: end,
    );
    expect(r.pct, closeTo(50, 0.001));
  });

  test('a lone sample carries at most maxCarry', () {
    final r = calc.compute(
      samples: [at(0, 70)],
      band: band,
      windowStart: start,
      windowEnd: end,
    );
    expect(r.covered, const Duration(minutes: 90));
    expect(r.coveredFraction, closeTo(90 / (24 * 60), 0.0001));
    expect(r.coverageSufficient, isFalse);
    expect(r.pct, closeTo(100, 0.001));
  });

  test('gaps longer than maxCarry are uncovered, not assumed', () {
    // One in-range sample, then a 6 h gap, then out-of-range samples.
    final samples = [at(0, 70), at(6 * 60, 90), at(6 * 60 + 5, 90)];
    final r = calc.compute(
      samples: samples,
      band: band,
      windowStart: start,
      windowEnd: start.add(const Duration(hours: 7)),
    );
    // 90 min in range + 5 min out + 55 min carry out (capped to window end).
    expect(r.inRange, const Duration(minutes: 90));
    expect(r.covered, const Duration(minutes: 90 + 5 + 55));
  });

  test('samples before the window only count from windowStart', () {
    final samples = [
      TimedSample(start.subtract(const Duration(minutes: 30)), 70),
      at(30, 70),
    ];
    final r = calc.compute(
      samples: samples,
      band: band,
      windowStart: start,
      windowEnd: start.add(const Duration(hours: 1)),
    );
    expect(r.covered, const Duration(hours: 1));
  });

  test('samples after the window are ignored', () {
    final r = calc.compute(
      samples: [TimedSample(end.add(const Duration(minutes: 1)), 70)],
      band: band,
      windowStart: start,
      windowEnd: end,
    );
    expect(r.pct, isNull);
  });

  test('unsorted input is sorted first', () {
    final samples = [at(60, 90), at(0, 70), at(30, 70)];
    final r = calc.compute(
      samples: samples,
      band: band,
      windowStart: start,
      windowEnd: start.add(const Duration(hours: 2)),
    );
    // 0–60 in range, 60–120 (capped 90 carry → 60–150 but window ends 120) out.
    expect(r.inRange, const Duration(minutes: 60));
    expect(r.covered, const Duration(minutes: 120));
    expect(r.pct, closeTo(50, 0.001));
  });

  test('NaN samples are skipped', () {
    final r = calc.compute(
      samples: [at(0, double.nan), at(5, 70)],
      band: band,
      windowStart: start,
      windowEnd: start.add(const Duration(minutes: 10)),
    );
    expect(r.covered, const Duration(minutes: 5));
  });

  test('minimumCoverage threshold is respected', () {
    const strict = TimeInRangeCalculator(minimumCoverage: 0.9);
    final samples = [for (var m = 0; m < 20 * 60; m += 5) at(m, 70.0)];
    final r = strict.compute(
      samples: samples,
      band: band,
      windowStart: start,
      windowEnd: end,
    );
    expect(
      r.coveredFraction,
      closeTo(20 / 24 + (90 / (24 * 60)) - (5 / (24 * 60)), 0.05),
    );
    expect(r.coverageSufficient, isFalse);
  });
}
