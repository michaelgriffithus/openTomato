import '../../../varieties/domain/enums/growth_habit.dart';
import '../../../varieties/domain/enums/variety_category.dart';

class VarietyModel {
  final int id;
  final String name;
  final GrowthHabit habit;
  final VarietyCategory category;
  final int? daysToMaturity;
  final String? notes;
  final bool userCreated;

  const VarietyModel({
    required this.id,
    required this.name,
    required this.habit,
    required this.category,
    required this.daysToMaturity,
    required this.notes,
    required this.userCreated,
  });
}
