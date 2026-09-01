import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/ai_settings_dao.dart';
import 'daos/app_settings_dao.dart';
import 'daos/assistant_dao.dart';
import 'daos/environment_snapshots_dao.dart';
import 'daos/grow_spaces_dao.dart';
import 'daos/ha_settings_dao.dart';
import 'daos/journal_entries_dao.dart';
import 'daos/journal_photos_dao.dart';
import 'daos/plants_dao.dart';
import 'daos/todos_dao.dart';
import 'daos/varieties_dao.dart';
import 'tables/ai_settings.dart';
import 'tables/app_settings.dart';
import 'tables/assistant_conversations.dart';
import 'tables/assistant_messages.dart';
import 'tables/entry_plant_associations.dart';
import 'tables/environment_snapshots.dart';
import 'tables/grow_space_stage_targets.dart';
import 'tables/grow_spaces.dart';
import 'tables/home_assistant_settings.dart';
import 'tables/journal_entries.dart';
import 'tables/journal_nutrient_rows.dart';
import 'tables/journal_photos.dart';
import 'tables/plant_stage_history.dart';
import 'tables/plants.dart';
import 'tables/todo_items.dart';
import 'tables/varieties.dart';

export 'daos/ai_settings_dao.dart';
export 'daos/app_settings_dao.dart';
export 'daos/assistant_dao.dart';
export 'daos/environment_snapshots_dao.dart';
export 'daos/grow_spaces_dao.dart';
export 'daos/ha_settings_dao.dart';
export 'daos/journal_entities.dart';
export 'daos/journal_entries_dao.dart';
export 'daos/journal_photos_dao.dart';
export 'daos/plants_dao.dart';
export 'daos/todos_dao.dart';
export 'daos/varieties_dao.dart';

part 'database.g.dart';

/// Reserved id of the grow space that exists on every install.
const String kDefaultGrowSpaceId = 'default';

@DriftDatabase(
  tables: [
    Varieties,
    Plants,
    PlantStageHistoryTable,
    JournalEntries,
    JournalPhotos,
    JournalNutrientRows,
    EntryPlantAssociations,
    TodoItems,
    AppSettings,
    HomeAssistantSettings,
    GrowSpaces,
    GrowSpaceStageTargets,
    EnvironmentSnapshots,
    AiSettings,
    AssistantConversations,
    AssistantMessages,
  ],
  daos: [
    VarietiesDao,
    PlantsDao,
    JournalEntriesDao,
    JournalPhotosDao,
    TodosDao,
    AppSettingsDao,
    HaSettingsDao,
    GrowSpacesDao,
    EnvironmentSnapshotsDao,
    AiSettingsDao,
    AssistantDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  /// MUST equal the pubspec build number. See CONVENTIONS.md.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // DDL only. One block per version, each wrapped in transaction():
        //   if (from < 2) {
        //     await transaction(() async {
        //       await m.addColumn(...);
        //     });
        //   }
        // Data backfills go through a separate service, never inline here.
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        await _ensureDefaultGrowSpace();
      },
    );
  }

  Future<void> _ensureDefaultGrowSpace() async {
    final existing = await (select(growSpaces)
          ..where((t) => t.id.equals(kDefaultGrowSpaceId)))
        .getSingleOrNull();
    if (existing != null) return;
    await into(growSpaces).insert(
      GrowSpacesCompanion.insert(
        id: kDefaultGrowSpaceId,
        name: 'My grow space',
        isDefault: const Value(true),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'opentomato.db'));
    return NativeDatabase(file);
  });
}
