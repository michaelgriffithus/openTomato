import 'package:flutter_test/flutter_test.dart';
import 'package:open_tomato/features/environment/domain/tomato_stage_bands.dart';
import 'package:open_tomato/features/plants/domain/enums/growth_stage.dart';

void main() {
  const bands = TomatoStageBands();

  group('normalizeStage', () {
    test('maps every grow-active stage storage value to itself', () {
      for (final stage in GrowthStage.values.where((s) => s.isGrowActive)) {
        expect(bands.normalizeStage(stage.storageValue), stage.storageValue);
      }
    });

    test('accepts loose spellings', () {
      expect(bands.normalizeStage(' Veg '), 'vegetative');
      expect(bands.normalizeStage('Fruit Set'), 'fruit_set');
      expect(bands.normalizeStage('harvest'), 'harvesting');
    });

    test('done, archived, empty and unknown resolve to null', () {
      expect(bands.normalizeStage('done'), isNull);
      expect(bands.normalizeStage('archived'), isNull);
      expect(bands.normalizeStage(''), isNull);
      expect(bands.normalizeStage(null), isNull);
      expect(bands.normalizeStage('cabbage'), isNull);
    });
  });

  group('resolve', () {
    test('returns the stage band without fallback for known stages', () {
      final r = bands.resolve('ripening');
      expect(r.stageKey, 'ripening');
      expect(r.stageFallbackUsed, isFalse);
      expect(r.bands, same(TomatoStageBands.ripening));
    });

    test('uses the fallback band for unknown stages', () {
      final r = bands.resolve('done');
      expect(r.stageKey, TomatoStageBands.fallbackKey);
      expect(r.stageFallbackUsed, isTrue);
      expect(r.bands, same(TomatoStageBands.fallback));
    });

    test('resolveStage matches resolve on storage value', () {
      expect(
        bands.resolveStage(GrowthStage.fruitSet).stageKey,
        bands.resolve('fruit_set').stageKey,
      );
    });
  });

  group('built-in bands are sane', () {
    for (final key in TomatoStageBands.editableStageKeys) {
      test('$key: ideal inside safety, min below max', () {
        final b = TomatoStageBands.builtinFor(key);
        expect(b.temperatureF.min, lessThan(b.temperatureF.max));
        expect(b.humidityPct.min, lessThan(b.humidityPct.max));
        expect(b.vpdKpa.min, lessThan(b.vpdKpa.max));
        expect(b.safetyTemperatureF.min, lessThanOrEqualTo(b.temperatureF.min));
        expect(
          b.safetyTemperatureF.max,
          greaterThanOrEqualTo(b.temperatureF.max),
        );
        expect(b.safetyHumidityPct.min, lessThanOrEqualTo(b.humidityPct.min));
        expect(
          b.safetyHumidityPct.max,
          greaterThanOrEqualTo(b.humidityPct.max),
        );
      });
    }

    test('flowering safety ceiling protects pollen', () {
      expect(TomatoStageBands.flowering.safetyTemperatureF.max, 88);
    });
  });

  test('ResolvedBand.contains is inclusive', () {
    const band = ResolvedBand(min: 60, max: 80);
    expect(band.contains(60), isTrue);
    expect(band.contains(80), isTrue);
    expect(band.contains(59.9), isFalse);
    expect(band.contains(80.1), isFalse);
  });

  test('labelFor', () {
    expect(TomatoStageBands.labelFor('fruit_set'), 'Fruit set');
    expect(TomatoStageBands.labelFor('fallback'), 'No active plant');
  });
}
