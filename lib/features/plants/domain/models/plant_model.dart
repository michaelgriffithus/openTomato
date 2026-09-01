import '../enums/growth_stage.dart';
import '../enums/start_method.dart';

class PlantModel {
  final int id;
  final String name;
  final int? varietyId;
  final DateTime startDate;
  final StartMethod startMethod;
  final GrowthStage stage;
  final DateTime? stageStartedAt;
  final String? growSpaceId;
  final String? location;
  final String? container;
  final String? medium;
  final String? notes;
  final DateTime? harvestedAt;
  final String? harvestNotes;
  final DateTime createdAt;
  final DateTime? archivedAt;

  const PlantModel({
    required this.id,
    required this.name,
    required this.varietyId,
    required this.startDate,
    required this.startMethod,
    required this.stage,
    required this.stageStartedAt,
    required this.growSpaceId,
    required this.location,
    required this.container,
    required this.medium,
    required this.notes,
    required this.harvestedAt,
    required this.harvestNotes,
    required this.createdAt,
    required this.archivedAt,
  });

  bool get isArchived => archivedAt != null;
}
