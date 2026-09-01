import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_tomato/core/database/database.dart';
import 'package:open_tomato/features/environment/data/stage_target_resolver.dart';
import 'package:open_tomato/features/environment/data/stage_targets_settings_service.dart';
import 'package:open_tomato/features/environment/domain/tomato_stage_bands.dart';

void main() {
  late AppDatabase db;
  late StageTargetResolver resolver;
  late StageTargetsSettingsService settings;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    settings = StageTargetsSettingsService(dao: db.appSettingsDao);
    resolver = StageTargetResolver(
      growSpaces: db.growSpacesDao,
      appDefaults: settings,
    );
  });

  tearDown(() => db.close());

  test('default grow space exists after open', () async {
    final space = await db.growSpacesDao.getDefaultGrowSpace();
    expect(space, isNotNull);
    expect(space!.isDefault, isTrue);
  });

  test('builtin tier when nothing is stored', () async {
    final r =
        await resolver.resolve(growSpaceId: 'default', stageKey: 'vegetative');
    expect(r.stageKey, 'vegetative');
    expect(r.bands.temperatureF, TomatoStageBands.vegetative.temperatureF);
    expect(r.temperatureSource, StageTargetSource.builtin);
    expect(r.hasOverride, isFalse);
  });

  test('unknown stage resolves to fallback', () async {
    final r = await resolver.resolve(growSpaceId: 'default', stageKey: 'done');
    expect(r.stageKey, TomatoStageBands.fallbackKey);
    expect(r.bands.vpdKpa, TomatoStageBands.fallback.vpdKpa);
  });

  test('app default beats builtin, per metric', () async {
    await settings.saveEditableBands({
      'vegetative': const EditableStageTargetBands(
        tempMinF: 66,
        tempMaxF: 84,
        humidityMinPct: 50,
        humidityMaxPct: 75,
        vpdMinKpa: 0.7,
        vpdMaxKpa: 1.3,
      ),
    });
    final r =
        await resolver.resolve(growSpaceId: 'default', stageKey: 'vegetative');
    expect(r.bands.temperatureF, const ResolvedBand(min: 66, max: 84));
    expect(r.temperatureSource, StageTargetSource.appDefault);
    expect(r.hasOverride, isTrue);
    // Safety bands are never overridden.
    expect(
      r.bands.safetyTemperatureF,
      TomatoStageBands.vegetative.safetyTemperatureF,
    );
  });

  test('grow space row beats app default, but only with both min and max',
      () async {
    await settings.saveEditableBands({
      'vegetative': const EditableStageTargetBands(
        tempMinF: 66,
        tempMaxF: 84,
        humidityMinPct: 50,
        humidityMaxPct: 75,
        vpdMinKpa: 0.7,
        vpdMaxKpa: 1.3,
      ),
    });
    await db.growSpacesDao.upsertStageTarget(
      GrowSpaceStageTargetsCompanion.insert(
        growSpaceId: 'default',
        stageKey: 'vegetative',
        tempMinF: const Value(72),
        tempMaxF: const Value(78),
        humidityMinPct: const Value(60), // max missing → tier skipped
      ),
    );
    final r =
        await resolver.resolve(growSpaceId: 'default', stageKey: 'vegetative');
    expect(r.bands.temperatureF, const ResolvedBand(min: 72, max: 78));
    expect(r.temperatureSource, StageTargetSource.growSpace);
    expect(r.bands.humidityPct, const ResolvedBand(min: 50, max: 75));
    expect(r.humiditySource, StageTargetSource.appDefault);
    expect(r.vpdSource, StageTargetSource.appDefault);
  });

  test('inverted grow-space band is ignored', () async {
    await db.growSpacesDao.upsertStageTarget(
      GrowSpaceStageTargetsCompanion.insert(
        growSpaceId: 'default',
        stageKey: 'ripening',
        vpdMinKpa: const Value(1.5),
        vpdMaxKpa: const Value(1.0),
      ),
    );
    final r =
        await resolver.resolve(growSpaceId: 'default', stageKey: 'ripening');
    expect(r.vpdSource, StageTargetSource.builtin);
  });

  test('settings service round-trips and resets', () async {
    const bands = EditableStageTargetBands(
      tempMinF: 60,
      tempMaxF: 70,
      humidityMinPct: 40,
      humidityMaxPct: 60,
      vpdMinKpa: 1.0,
      vpdMaxKpa: 1.5,
    );
    await settings.saveEditableBands({'Fruit Set': bands});
    final loaded = await settings.getCustomBands('fruit_set');
    expect(loaded!.toJson(), bands.toJson());
    await settings.resetStage('fruit_set');
    expect(await settings.getCustomBands('fruit_set'), isNull);
    final editable = await settings.getEditableBands();
    expect(editable.keys, TomatoStageBands.editableStageKeys);
  });

  test('corrupt stored JSON surfaces as a ParseException', () async {
    await db.appSettingsDao.setSetting(
      StageTargetsSettingsService.keyForStage('seedling'),
      '{not json',
    );
    expect(
      () => settings.getCustomBands('seedling'),
      throwsA(isA<Exception>()),
    );
  });
}
