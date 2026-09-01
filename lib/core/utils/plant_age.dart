/// Canonical plant-age calculation: the single source of truth for "how old
/// is this plant". The primary age is measured from the recorded emergence
/// date when one is validly recorded, falling back to the recorded start date
/// otherwise, so slow germination never inflates the biological age. "Since
/// planting" stays available as a secondary metric.
library;

/// Which recorded date the primary age is measured from.
enum PlantAgeBasis {
  emergence,
  recordedStartDate;

  String get wireName => switch (this) {
        PlantAgeBasis.emergence => 'emergence',
        PlantAgeBasis.recordedStartDate => 'recorded_start_date',
      };
}

class PlantAge {
  /// Primary age in whole calendar days: emergence-based when the recorded
  /// emergence date is valid, otherwise seed-start based. Null when neither
  /// date yields a usable age (see [reason]).
  final int? days;

  /// Basis for [days]; null when [days] is null.
  final PlantAgeBasis? basis;

  /// Why [days] is null: 'start_date_missing', 'start_date_in_future', or
  /// 'lifecycle_dates_conflict'.
  final String? reason;

  /// Secondary "since planting" metric — always seed-start based, regardless
  /// of [basis]. Present whenever the seed-start date itself is usable, even
  /// when the primary age uses emergence.
  final int? daysSincePlanting;

  const PlantAge({
    required this.days,
    required this.basis,
    required this.reason,
    required this.daysSincePlanting,
  });

  bool get isKnown => days != null;
}

/// Computes the canonical [PlantAge] for a plant.
///
/// [stageStartedAt] is optional and only participates in the
/// `lifecycle_dates_conflict` guard (a stage start outside
/// `[startDate, now]` marks the seed-start age unusable). A validly recorded emergence date makes
/// the primary age emergence-based even when the seed-start age is unusable.
PlantAge plantAge({
  required DateTime? startDate,
  DateTime? emergedAt,
  DateTime? stageStartedAt,
  DateTime? now,
}) {
  final effectiveNow = now ?? DateTime.now();
  final nowDay = calendarDayOf(effectiveNow);
  final startDay = startDate == null ? null : calendarDayOf(startDate);
  final stageDay =
      stageStartedAt == null ? null : calendarDayOf(stageStartedAt);

  String? sinceReason;
  int? daysSincePlanting;
  if (startDay == null) {
    sinceReason = 'start_date_missing';
  } else if (startDay.isAfter(nowDay)) {
    sinceReason = 'start_date_in_future';
  } else if (stageDay != null &&
      (stageDay.isBefore(startDay) || stageDay.isAfter(nowDay))) {
    sinceReason = 'lifecycle_dates_conflict';
  } else {
    daysSincePlanting = nowDay.difference(startDay).inDays;
  }

  if (isValidEmergence(
    emergedAt: emergedAt,
    startDate: startDate,
    now: effectiveNow,
  )) {
    return PlantAge(
      days: nowDay.difference(calendarDayOf(emergedAt!)).inDays,
      basis: PlantAgeBasis.emergence,
      reason: null,
      daysSincePlanting: daysSincePlanting,
    );
  }

  return PlantAge(
    days: daysSincePlanting,
    basis: daysSincePlanting == null ? null : PlantAgeBasis.recordedStartDate,
    reason: sinceReason,
    daysSincePlanting: daysSincePlanting,
  );
}

/// Whether a recorded emergence date is usable as an age basis: recorded, not
/// in the future, and not before the seed-start date (when one is known).
bool isValidEmergence({
  required DateTime? emergedAt,
  required DateTime? startDate,
  required DateTime now,
}) {
  if (emergedAt == null) {
    return false;
  }
  final emergedDay = calendarDayOf(emergedAt);
  final nowDay = calendarDayOf(now);
  final startDay = startDate == null ? null : calendarDayOf(startDate);
  return !emergedDay.isAfter(nowDay) &&
      (startDay == null || !emergedDay.isBefore(startDay));
}

/// Day-numbering for an arbitrary historical timestamp (journal entries,
/// photos, replay frames). Day 1 is the day of the age anchor — the recorded
/// emergence date when valid, else the seed-start date.
class PlantTimelineDay {
  /// 1-based day number from the age anchor; null when the timestamp predates
  /// the grow entirely or no anchor date is usable.
  final int? dayNumber;

  /// True when the timestamp falls after the seed start but before a validly
  /// recorded emergence — render a germination-style label instead of a
  /// growth-day number.
  final bool isPreEmergence;

  const PlantTimelineDay({
    required this.dayNumber,
    required this.isPreEmergence,
  });
}

PlantTimelineDay plantTimelineDayFor({
  required DateTime timestamp,
  required DateTime? startDate,
  DateTime? emergedAt,
  DateTime? now,
}) {
  final timestampDay = calendarDayOf(timestamp);
  final startDay = startDate == null ? null : calendarDayOf(startDate);
  if (startDay != null && timestampDay.isBefore(startDay)) {
    return const PlantTimelineDay(dayNumber: null, isPreEmergence: false);
  }
  if (isValidEmergence(
    emergedAt: emergedAt,
    startDate: startDate,
    now: now ?? DateTime.now(),
  )) {
    final emergedDay = calendarDayOf(emergedAt!);
    if (timestampDay.isBefore(emergedDay)) {
      return const PlantTimelineDay(dayNumber: null, isPreEmergence: true);
    }
    return PlantTimelineDay(
      dayNumber: timestampDay.difference(emergedDay).inDays + 1,
      isPreEmergence: false,
    );
  }
  if (startDay == null) {
    return const PlantTimelineDay(dayNumber: null, isPreEmergence: false);
  }
  return PlantTimelineDay(
    dayNumber: timestampDay.difference(startDay).inDays + 1,
    isPreEmergence: false,
  );
}

/// UTC calendar-day truncation shared by every age calculation so that age
/// differences are whole calendar days regardless of time of day or offset
/// regardless of time zone.
DateTime calendarDayOf(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);
