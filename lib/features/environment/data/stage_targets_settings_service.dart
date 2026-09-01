import 'dart:convert';

import '../../../core/database/daos/app_settings_dao.dart';
import '../../../core/errors/app_exceptions.dart';
import '../domain/tomato_stage_bands.dart';

/// The six numbers a grower can edit for one stage.
class EditableStageTargetBands {
  final double tempMinF;
  final double tempMaxF;
  final double humidityMinPct;
  final double humidityMaxPct;
  final double vpdMinKpa;
  final double vpdMaxKpa;

  const EditableStageTargetBands({
    required this.tempMinF,
    required this.tempMaxF,
    required this.humidityMinPct,
    required this.humidityMaxPct,
    required this.vpdMinKpa,
    required this.vpdMaxKpa,
  });

  factory EditableStageTargetBands.fromResolved(
    ResolvedStageTargetBands bands,
  ) {
    return EditableStageTargetBands(
      tempMinF: bands.temperatureF.min,
      tempMaxF: bands.temperatureF.max,
      humidityMinPct: bands.humidityPct.min,
      humidityMaxPct: bands.humidityPct.max,
      vpdMinKpa: bands.vpdKpa.min,
      vpdMaxKpa: bands.vpdKpa.max,
    );
  }

  factory EditableStageTargetBands.fromJson(Map<String, dynamic> json) {
    return EditableStageTargetBands(
      tempMinF: (json['tempMinF'] as num).toDouble(),
      tempMaxF: (json['tempMaxF'] as num).toDouble(),
      humidityMinPct: (json['humidityMinPct'] as num).toDouble(),
      humidityMaxPct: (json['humidityMaxPct'] as num).toDouble(),
      vpdMinKpa: (json['vpdMinKpa'] as num).toDouble(),
      vpdMaxKpa: (json['vpdMaxKpa'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'tempMinF': tempMinF,
        'tempMaxF': tempMaxF,
        'humidityMinPct': humidityMinPct,
        'humidityMaxPct': humidityMaxPct,
        'vpdMinKpa': vpdMinKpa,
        'vpdMaxKpa': vpdMaxKpa,
      };

  bool get isValid =>
      tempMinF < tempMaxF &&
      humidityMinPct < humidityMaxPct &&
      vpdMinKpa < vpdMaxKpa;

  /// Ideal bands from this object; safety bands from the built-in stage.
  ResolvedStageTargetBands toResolvedBands(String stageKey) {
    return TomatoStageBands.builtinFor(stageKey).copyWith(
      temperatureF: ResolvedBand(min: tempMinF, max: tempMaxF),
      humidityPct: ResolvedBand(min: humidityMinPct, max: humidityMaxPct),
      vpdKpa: ResolvedBand(min: vpdMinKpa, max: vpdMaxKpa),
    );
  }
}

/// App-wide stage band overrides, stored as JSON in app_settings.
class StageTargetsSettingsService {
  final AppSettingsDao _dao;
  final TomatoStageBands _defaults;

  const StageTargetsSettingsService({
    required AppSettingsDao dao,
    TomatoStageBands defaults = const TomatoStageBands(),
  })  : _dao = dao,
        _defaults = defaults;

  static String keyForStage(String stageKey) => 'environment_targets.$stageKey';

  Future<EditableStageTargetBands?> getCustomBands(String stageKey) async {
    final key = _normalize(stageKey);
    if (key == null) return null;
    final raw = await _dao.getSetting(keyForStage(key));
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw ParseException('Stage target payload for $key is not an object.');
      }
      return EditableStageTargetBands.fromJson(decoded);
    } on FormatException catch (error) {
      throw ParseException('Stage target payload for $key is invalid: $error');
    }
  }

  Future<EditableStageTargetBands> getBandsOrDefault(String stageKey) async {
    final key = _normalize(stageKey) ?? TomatoStageBands.fallbackKey;
    final custom = await getCustomBands(key);
    if (custom != null) return custom;
    return EditableStageTargetBands.fromResolved(
      TomatoStageBands.builtinFor(key),
    );
  }

  Future<Map<String, EditableStageTargetBands>> getEditableBands() async {
    final result = <String, EditableStageTargetBands>{};
    for (final stageKey in TomatoStageBands.editableStageKeys) {
      result[stageKey] = await getBandsOrDefault(stageKey);
    }
    return result;
  }

  Future<void> saveEditableBands(
    Map<String, EditableStageTargetBands> values,
  ) async {
    for (final entry in values.entries) {
      final key = _normalize(entry.key);
      if (key == null) continue;
      await _dao.setSetting(keyForStage(key), jsonEncode(entry.value.toJson()));
    }
  }

  Future<void> resetStage(String stageKey) async {
    final key = _normalize(stageKey);
    if (key == null) return;
    await _dao.deleteSetting(keyForStage(key));
  }

  String? _normalize(String? raw) {
    if (raw == TomatoStageBands.fallbackKey) return raw;
    return _defaults.normalizeStage(raw);
  }
}
