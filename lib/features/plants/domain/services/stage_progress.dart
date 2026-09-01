import '../../../../core/utils/plant_age.dart';

/// Simple day counts for a plant: how long it has been alive, how long in the
/// current stage, and how far along it is toward the variety's days to
/// maturity (counted from the start date).
class StageProgress {
  final int? daysSinceStart;
  final int? daysInStage;
  final int? daysToMaturity;

  const StageProgress({
    required this.daysSinceStart,
    required this.daysInStage,
    required this.daysToMaturity,
  });

  /// 0–1 progress toward maturity, or null when unknown.
  double? get maturityFraction {
    final dtm = daysToMaturity;
    final days = daysSinceStart;
    if (dtm == null || dtm <= 0 || days == null) return null;
    return (days / dtm).clamp(0.0, 1.0);
  }

  int? get daysToExpectedMaturity {
    final dtm = daysToMaturity;
    final days = daysSinceStart;
    if (dtm == null || days == null) return null;
    return dtm - days;
  }
}

StageProgress stageProgress({
  required DateTime? startDate,
  required DateTime? stageStartedAt,
  required int? daysToMaturity,
  DateTime? now,
}) {
  final effectiveNow = now ?? DateTime.now();
  final age = plantAge(startDate: startDate, now: effectiveNow);
  int? daysInStage;
  if (stageStartedAt != null) {
    final diff = calendarDayOf(effectiveNow)
        .difference(calendarDayOf(stageStartedAt))
        .inDays;
    daysInStage = diff < 0 ? null : diff;
  }
  return StageProgress(
    daysSinceStart: age.daysSincePlanting,
    daysInStage: daysInStage,
    daysToMaturity: daysToMaturity,
  );
}
