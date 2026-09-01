import '../../../environment/domain/environment_range_evaluator.dart';
import '../../../environment/presentation/providers/environment_providers.dart';

enum TodayState { unconfigured, noReadings, ready }

enum StatusTone { good, near, bad, muted }

class ReadingTile {
  final String label;
  final String valueText;
  final String unitText;
  final String statusLabel;
  final StatusTone tone;
  final String bandText;

  const ReadingTile({
    required this.label,
    required this.valueText,
    required this.unitText,
    required this.statusLabel,
    required this.tone,
    required this.bandText,
  });
}

class TimeInRangeTile {
  final String label;
  final double? pct;
  final bool coverageOk;
  final String coverageText;

  const TimeInRangeTile({
    required this.label,
    required this.pct,
    required this.coverageOk,
    required this.coverageText,
  });
}

class TracePoint {
  final DateTime at;
  final double value;

  const TracePoint(this.at, this.value);
}

class TraceContract {
  final EnvironmentMetric metric;
  final List<TracePoint> points;
  final double bandMin;
  final double bandMax;
  final DateTime windowStart;
  final DateTime windowEnd;

  const TraceContract({
    required this.metric,
    required this.points,
    required this.bandMin,
    required this.bandMax,
    required this.windowStart,
    required this.windowEnd,
  });
}

class TodayPlantChip {
  final int id;
  final String name;
  final String stageLabel;
  final String dayLabel;

  const TodayPlantChip({
    required this.id,
    required this.name,
    required this.stageLabel,
    required this.dayLabel,
  });
}

class GrowSpaceChoice {
  final String id;
  final String name;

  const GrowSpaceChoice({required this.id, required this.name});
}

class TodayContract {
  final TodayState state;
  final String growSpaceName;
  final String growSpaceId;
  final List<GrowSpaceChoice> growSpaceChoices;
  final String freshnessLabel;
  final StatusTone freshnessTone;
  final String stageLabel;
  final bool bandsOverridden;
  final List<ReadingTile> readings;
  final String focusLine;
  final ReadingWindow selectedWindow;
  final List<TimeInRangeTile> timeInRange;
  final TraceContract? trace;
  final EnvironmentMetric traceMetric;
  final List<TodayPlantChip> plants;
  final bool backfillRunning;

  const TodayContract({
    required this.state,
    required this.growSpaceName,
    required this.growSpaceId,
    required this.growSpaceChoices,
    required this.freshnessLabel,
    required this.freshnessTone,
    required this.stageLabel,
    required this.bandsOverridden,
    required this.readings,
    required this.focusLine,
    required this.selectedWindow,
    required this.timeInRange,
    required this.trace,
    required this.traceMetric,
    required this.plants,
    required this.backfillRunning,
  });
}
