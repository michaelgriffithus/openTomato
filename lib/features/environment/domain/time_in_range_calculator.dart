import 'tomato_stage_bands.dart';

/// A timestamped value for one metric.
class TimedSample {
  final DateTime at;
  final double value;

  const TimedSample(this.at, this.value);
}

class TimeInRangeResult {
  /// Share of covered time spent inside the band, 0–100. Null when nothing
  /// was covered.
  final double? pct;

  /// Share of the window for which readings existed, 0–1.
  final double coveredFraction;

  /// Whether enough of the window was covered to trust [pct].
  final bool coverageSufficient;

  final Duration inRange;
  final Duration covered;
  final Duration window;

  const TimeInRangeResult({
    required this.pct,
    required this.coveredFraction,
    required this.coverageSufficient,
    required this.inRange,
    required this.covered,
    required this.window,
  });

  static const empty = TimeInRangeResult(
    pct: null,
    coveredFraction: 0,
    coverageSufficient: false,
    inRange: Duration.zero,
    covered: Duration.zero,
    window: Duration.zero,
  );
}

/// Time-weighted time-in-range over a window. Each sample holds until the
/// next one, capped at [maxCarry], so a gap in recording counts as
/// uncovered rather than as whatever the last reading happened to be.
class TimeInRangeCalculator {
  const TimeInRangeCalculator({
    this.maxCarry = const Duration(minutes: 90),
    this.minimumCoverage = 0.5,
  });

  final Duration maxCarry;

  /// Fraction of the window that must be covered for [TimeInRangeResult.pct]
  /// to be trusted.
  final double minimumCoverage;

  TimeInRangeResult compute({
    required List<TimedSample> samples,
    required ResolvedBand band,
    required DateTime windowStart,
    required DateTime windowEnd,
  }) {
    final window = windowEnd.difference(windowStart);
    if (window <= Duration.zero) return TimeInRangeResult.empty;

    final sorted = samples.where((s) => s.value.isFinite).toList()
      ..sort((a, b) => a.at.compareTo(b.at));

    var inRange = Duration.zero;
    var covered = Duration.zero;

    for (var i = 0; i < sorted.length; i++) {
      final sample = sorted[i];
      final start = _later(sample.at, windowStart);
      if (start.isAfter(windowEnd)) break;

      final naturalEnd = i + 1 < sorted.length ? sorted[i + 1].at : windowEnd;
      final cappedEnd = _earlier(
        _earlier(naturalEnd, sample.at.add(maxCarry)),
        windowEnd,
      );
      if (!cappedEnd.isAfter(start)) continue;

      final held = cappedEnd.difference(start);
      covered += held;
      if (band.contains(sample.value)) {
        inRange += held;
      }
    }

    if (covered == Duration.zero) {
      return TimeInRangeResult(
        pct: null,
        coveredFraction: 0,
        coverageSufficient: false,
        inRange: Duration.zero,
        covered: Duration.zero,
        window: window,
      );
    }

    final coveredFraction = covered.inMilliseconds / window.inMilliseconds;
    return TimeInRangeResult(
      pct: inRange.inMilliseconds / covered.inMilliseconds * 100,
      coveredFraction: coveredFraction,
      coverageSufficient: coveredFraction >= minimumCoverage,
      inRange: inRange,
      covered: covered,
      window: window,
    );
  }

  DateTime _later(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
  DateTime _earlier(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
}
