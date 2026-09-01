import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_tomato/core/database/database.dart';
import 'package:open_tomato/features/varieties/data/repositories/varieties_repository.dart';
import 'package:open_tomato/features/varieties/data/seed_data/variety_seeds.dart';
import 'package:open_tomato/features/varieties/domain/enums/growth_habit.dart';
import 'package:open_tomato/features/varieties/domain/enums/variety_category.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('seed names are unique', () {
    final names = VarietySeeds.seeds.map((s) => s.name).toSet();
    expect(names.length, VarietySeeds.seeds.length);
  });

  test('seeding is idempotent and preserves user varieties', () async {
    await VarietySeeds.seedDatabase(db);
    final first = await db.varietiesDao.countVarieties();
    expect(first, VarietySeeds.seeds.length);

    final repo = VarietiesRepository(db.varietiesDao);
    final id = await repo.create(
      name: 'Grandma\'s Red',
      habit: GrowthHabit.indeterminate,
      category: VarietyCategory.heirloom,
      daysToMaturity: 80,
    );
    await db.varietiesDao.deleteVariety(
      (await db.varietiesDao.getVarietyByName('Roma'))!.id,
    );

    await VarietySeeds.seedDatabase(db);
    expect(
      await db.varietiesDao.countVarieties(),
      VarietySeeds.seeds.length + 1,
    );
    expect(await db.varietiesDao.getVarietyById(id), isNotNull);
    expect(await db.varietiesDao.getVarietyByName('Roma'), isNotNull);
  });

  test('enum storage values round-trip', () {
    for (final h in GrowthHabit.values) {
      expect(GrowthHabit.fromStorage(h.storageValue), h);
    }
    for (final c in VarietyCategory.values) {
      expect(VarietyCategory.fromStorage(c.storageValue), c);
    }
  });
}
