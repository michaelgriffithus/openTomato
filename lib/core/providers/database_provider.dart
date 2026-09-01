import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';

final AppDatabase _sharedAppDatabase = AppDatabase();

final databaseProvider = Provider<AppDatabase>((ref) {
  return _sharedAppDatabase;
});

final varietiesDaoProvider =
    Provider<VarietiesDao>((ref) => ref.watch(databaseProvider).varietiesDao);

final plantsDaoProvider =
    Provider<PlantsDao>((ref) => ref.watch(databaseProvider).plantsDao);

final journalEntriesDaoProvider = Provider<JournalEntriesDao>(
  (ref) => ref.watch(databaseProvider).journalEntriesDao,
);

final journalPhotosDaoProvider = Provider<JournalPhotosDao>(
  (ref) => ref.watch(databaseProvider).journalPhotosDao,
);

final todosDaoProvider =
    Provider<TodosDao>((ref) => ref.watch(databaseProvider).todosDao);

final appSettingsDaoProvider = Provider<AppSettingsDao>(
  (ref) => ref.watch(databaseProvider).appSettingsDao,
);

final haSettingsDaoProvider = Provider<HaSettingsDao>(
  (ref) => ref.watch(databaseProvider).haSettingsDao,
);

final growSpacesDaoProvider = Provider<GrowSpacesDao>(
  (ref) => ref.watch(databaseProvider).growSpacesDao,
);

final environmentSnapshotsDaoProvider = Provider<EnvironmentSnapshotsDao>(
  (ref) => ref.watch(databaseProvider).environmentSnapshotsDao,
);

final aiSettingsDaoProvider = Provider<AiSettingsDao>(
  (ref) => ref.watch(databaseProvider).aiSettingsDao,
);

final assistantDaoProvider = Provider<AssistantDao>(
  (ref) => ref.watch(databaseProvider).assistantDao,
);
