import '../../../core/database/database.dart';
import '../domain/tomato_stage_bands.dart';
import 'stage_targets_settings_service.dart';

enum StageTargetSource { growSpace, appDefault, builtin }

class ResolvedEnvironmentTargets {
  final String stageKey;
  final ResolvedStageTargetBands bands;

  /// Where each ideal band came from, per metric.
  final StageTargetSource temperatureSource;
  final StageTargetSource humiditySource;
  final StageTargetSource vpdSource;

  const ResolvedEnvironmentTargets({
    required this.stageKey,
    required this.bands,
    required this.temperatureSource,
    required this.humiditySource,
    required this.vpdSource,
  });

  bool get hasOverride =>
      temperatureSource != StageTargetSource.builtin ||
      humiditySource != StageTargetSource.builtin ||
      vpdSource != StageTargetSource.builtin;
}

/// Three tiers, highest first: the grow space's own row for the stage, the
/// app-wide default for the stage, then the built-in tomato band. A tier
/// wins a metric only when BOTH its min and max are set. Safety bands always
/// come from the built-in stage and cannot be overridden.
class StageTargetResolver {
  final GrowSpacesDao _growSpaces;
  final StageTargetsSettingsService _appDefaults;

  const StageTargetResolver({
    required GrowSpacesDao growSpaces,
    required StageTargetsSettingsService appDefaults,
  })  : _growSpaces = growSpaces,
        _appDefaults = appDefaults;

  Future<ResolvedEnvironmentTargets> resolve({
    required String growSpaceId,
    required String? stageKey,
  }) async {
    final key = const TomatoStageBands().normalizeStage(stageKey) ??
        TomatoStageBands.fallbackKey;
    final builtin = TomatoStageBands.builtinFor(key);

    final rows = await _growSpaces.getStageTargetsForGrowSpace(growSpaceId);
    GrowSpaceStageTarget? row;
    for (final candidate in rows) {
      if (candidate.stageKey == key) {
        row = candidate;
        break;
      }
    }
    final appDefault = await _appDefaults.getCustomBands(key);

    final temperature = _pick(
      growSpace: _band(row?.tempMinF, row?.tempMaxF),
      appDefault: appDefault == null
          ? null
          : ResolvedBand(min: appDefault.tempMinF, max: appDefault.tempMaxF),
      builtin: builtin.temperatureF,
    );
    final humidity = _pick(
      growSpace: _band(row?.humidityMinPct, row?.humidityMaxPct),
      appDefault: appDefault == null
          ? null
          : ResolvedBand(
              min: appDefault.humidityMinPct,
              max: appDefault.humidityMaxPct,
            ),
      builtin: builtin.humidityPct,
    );
    final vpd = _pick(
      growSpace: _band(row?.vpdMinKpa, row?.vpdMaxKpa),
      appDefault: appDefault == null
          ? null
          : ResolvedBand(min: appDefault.vpdMinKpa, max: appDefault.vpdMaxKpa),
      builtin: builtin.vpdKpa,
    );

    return ResolvedEnvironmentTargets(
      stageKey: key,
      bands: builtin.copyWith(
        temperatureF: temperature.band,
        humidityPct: humidity.band,
        vpdKpa: vpd.band,
      ),
      temperatureSource: temperature.source,
      humiditySource: humidity.source,
      vpdSource: vpd.source,
    );
  }

  ResolvedBand? _band(double? min, double? max) {
    if (min == null || max == null || min >= max) return null;
    return ResolvedBand(min: min, max: max);
  }

  ({ResolvedBand band, StageTargetSource source}) _pick({
    required ResolvedBand? growSpace,
    required ResolvedBand? appDefault,
    required ResolvedBand builtin,
  }) {
    if (growSpace != null) {
      return (band: growSpace, source: StageTargetSource.growSpace);
    }
    if (appDefault != null && appDefault.min < appDefault.max) {
      return (band: appDefault, source: StageTargetSource.appDefault);
    }
    return (band: builtin, source: StageTargetSource.builtin);
  }
}
