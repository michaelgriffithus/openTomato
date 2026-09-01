import 'package:drift/drift.dart';

import '../../../../core/database/database.dart';
import '../../domain/enums/growth_habit.dart';
import '../../domain/enums/variety_category.dart';

class VarietiesRepository {
  final VarietiesDao _dao;

  const VarietiesRepository(this._dao);

  Stream<List<Variety>> watchAll() => _dao.watchAllVarieties();

  Stream<List<Variety>> search(String query) => query.trim().isEmpty
      ? _dao.watchAllVarieties()
      : _dao.searchVarieties(query);

  Future<Variety?> getById(int id) => _dao.getVarietyById(id);

  Future<int> create({
    required String name,
    required GrowthHabit habit,
    required VarietyCategory category,
    int? daysToMaturity,
    String? notes,
  }) {
    return _dao.insertVariety(
      VarietiesCompanion.insert(
        name: name.trim(),
        growthHabit: habit.storageValue,
        category: category.storageValue,
        daysToMaturity: Value(daysToMaturity),
        notes: Value(_clean(notes)),
        userCreated: const Value(true),
      ),
    );
  }

  Future<bool> update(Variety variety) => _dao.updateVariety(variety);

  Future<int> delete(int id) => _dao.deleteVariety(id);

  String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
