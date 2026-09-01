import '../../../core/database/database.dart';
import '../../environment/domain/environment_range_evaluator.dart';
import '../../environment/domain/time_in_range_calculator.dart';
import '../../environment/domain/tomato_stage_bands.dart';
import '../../journal/data/models/journal_entry_with_details.dart';
import '../../plants/data/models/plant_with_variety.dart';
import '../../plants/domain/services/stage_progress.dart';

/// Everything the assistant is allowed to know, as one plain-text block the
/// grower can read in the UI. Never includes URLs, tokens, entity ids, or
/// file paths.
class GardenContextInput {
  final String growSpaceName;
  final String stageLabel;
  final ResolvedStageTargetBands? bands;
  final EnvironmentSnapshot? reading;
  final bool readingIsFresh;
  final EnvironmentEvaluation? evaluation;
  final TimeInRangeResult? vpdTimeInRange24h;
  final List<PlantWithVariety> plants;
  final List<JournalEntryWithPlantsAndPhotos> recentEntries;
  final List<TodoItem> openTasks;
  final DateTime now;

  const GardenContextInput({
    required this.growSpaceName,
    required this.stageLabel,
    required this.bands,
    required this.reading,
    required this.readingIsFresh,
    required this.evaluation,
    required this.vpdTimeInRange24h,
    required this.plants,
    required this.recentEntries,
    required this.openTasks,
    required this.now,
  });
}

class GardenContextBuilder {
  const GardenContextBuilder();

  String build(GardenContextInput input) {
    final b = StringBuffer()
      ..writeln('CONTEXT (from the OpenTomato app, ${_date(input.now)})');
    b.writeln(
      'Grow space: ${input.growSpaceName}. Stage for targets: ${input.stageLabel}.',
    );
    _readings(b, input);
    _plants(b, input);
    _entries(b, input);
    _tasks(b, input);
    return b.toString().trimRight();
  }

  void _readings(StringBuffer b, GardenContextInput input) {
    final r = input.reading;
    final bands = input.bands;
    if (r == null) {
      b.writeln('Readings: none recorded yet.');
    } else {
      final parts = [
        if (r.tempF != null) '${r.tempF!.round()} °F',
        if (r.rhPct != null) '${r.rhPct!.round()} % RH',
        if (r.vpdKpa != null) '${r.vpdKpa!.toStringAsFixed(2)} kPa VPD',
        if (r.soilMoisturePct != null)
          '${r.soilMoisturePct!.round()} % soil moisture',
      ];
      final age = input.now.difference(r.timestamp);
      final ageText = age.inMinutes < 60
          ? '${age.inMinutes} min ago'
          : '${age.inHours} h ago';
      b.writeln(
        'Latest reading (${input.readingIsFresh ? ageText : 'stale, $ageText'}): ${parts.join(', ')}.',
      );
    }
    if (bands != null) {
      b.writeln(
        'Target bands for this stage: temperature ${_band(bands.temperatureF)} °F, '
        'humidity ${_band(bands.humidityPct)} %, VPD ${_band(bands.vpdKpa)} kPa.',
      );
    }
    final eval = input.evaluation;
    if (eval != null && eval.hasAnyReading) {
      final flags = [
        for (final m in eval.metrics)
          if (m.status != MetricRangeStatus.unknown)
            '${m.metric.label.toLowerCase()} ${m.status.name}',
      ];
      b.writeln('Range check: ${flags.join(', ')}.');
    }
    final tir = input.vpdTimeInRange24h;
    if (tir != null && tir.pct != null) {
      b.writeln(
        'VPD time in range, last 24 h: ${tir.pct!.round()} % (${(tir.coveredFraction * 100).round()} % of the window covered).',
      );
    }
  }

  void _plants(StringBuffer b, GardenContextInput input) {
    if (input.plants.isEmpty) {
      b.writeln('Plants: none added yet.');
      return;
    }
    b.writeln('Plants:');
    for (final p in input.plants) {
      final progress = stageProgress(
        startDate: p.plant.startDate,
        stageStartedAt: p.plant.stageStartedAt,
        daysToMaturity: p.variety?.daysToMaturity,
        now: input.now,
      );
      final bits = [
        p.varietyLabel,
        p.plant.stage.displayName.toLowerCase(),
        if (progress.daysSinceStart != null)
          'day ${progress.daysSinceStart! + 1}',
        if (progress.daysInStage != null)
          '${progress.daysInStage! + 1} days in stage',
        if (progress.daysToExpectedMaturity != null &&
            progress.daysToExpectedMaturity! > 0)
          '~${progress.daysToExpectedMaturity} days to maturity',
      ];
      b.writeln('- ${p.plant.name}: ${bits.join(', ')}');
    }
  }

  void _entries(StringBuffer b, GardenContextInput input) {
    if (input.recentEntries.isEmpty) return;
    b.writeln('Recent journal entries:');
    for (final e in input.recentEntries.take(5)) {
      final names = e.plants.map((p) => p.name).join(', ');
      final content = e.entry.content?.trim().split('\n').first;
      final readings = [
        if (e.entry.tempF != null) '${e.entry.tempF!.round()} °F',
        if (e.entry.humidityPct != null) '${e.entry.humidityPct!.round()} %',
      ];
      b.writeln(
        '- ${_date(e.entry.timestamp)} ${e.entry.type.displayName}'
        '${names.isEmpty ? '' : ' ($names)'}'
        '${content == null || content.isEmpty ? '' : ': ${_clip(content, 120)}'}'
        '${readings.isEmpty ? '' : ' [${readings.join(', ')}]'}'
        '${e.photos.isEmpty ? '' : ' [${e.photos.length} photo${e.photos.length == 1 ? '' : 's'} not included]'}',
      );
    }
  }

  void _tasks(StringBuffer b, GardenContextInput input) {
    if (input.openTasks.isEmpty) return;
    b.writeln('Open tasks:');
    for (final t in input.openTasks.take(5)) {
      b.writeln('- ${t.title} (due ${_date(t.dueDate)})');
    }
  }

  String _band(ResolvedBand band) {
    String f(double v) =>
        v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(2);
    return '${f(band.min)}–${f(band.max)}';
  }

  String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _clip(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max - 1)}…';
}
