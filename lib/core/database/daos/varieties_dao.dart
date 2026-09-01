import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/varieties.dart';

part 'varieties_dao.g.dart';

@DriftAccessor(tables: [Varieties])
class VarietiesDao extends DatabaseAccessor<AppDatabase>
    with _$VarietiesDaoMixin {
  VarietiesDao(super.db);

  Stream<List<Variety>> watchAllVarieties() {
    return (select(varieties)..orderBy([(v) => OrderingTerm.asc(v.name)]))
        .watch();
  }

  Stream<List<Variety>> searchVarieties(String query) {
    return (select(varieties)
          ..where((v) => v.name.lower().like('%${query.toLowerCase()}%'))
          ..orderBy([(v) => OrderingTerm.asc(v.name)]))
        .watch();
  }

  Future<Variety?> getVarietyById(int id) {
    return (select(varieties)..where((v) => v.id.equals(id))).getSingleOrNull();
  }

  Future<Variety?> getVarietyByName(String name) {
    return (select(varieties)..where((v) => v.name.equals(name)))
        .getSingleOrNull();
  }

  Future<int> countVarieties() async {
    final count = varieties.id.count();
    final row = await (selectOnly(varieties)..addColumns([count])).getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> insertVariety(VarietiesCompanion variety) {
    return into(varieties).insert(variety);
  }

  Future<bool> updateVariety(Variety variety) {
    return update(varieties).replace(variety);
  }

  Future<int> deleteVariety(int id) {
    return (delete(varieties)..where((v) => v.id.equals(id))).go();
  }
}
