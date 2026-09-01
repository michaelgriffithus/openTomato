import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/plants_repository.dart';

class PlantsScreenController {
  const PlantsScreenController(this._ref);

  final Ref _ref;

  Future<void> archive(int plantId) =>
      _ref.read(plantsRepositoryProvider).archivePlant(plantId);

  Future<void> restore(int plantId) =>
      _ref.read(plantsRepositoryProvider).unarchivePlant(plantId);

  Future<void> delete(int plantId) =>
      _ref.read(plantsRepositoryProvider).deletePlant(plantId);
}

final plantsScreenControllerProvider = Provider<PlantsScreenController>(
  PlantsScreenController.new,
);
