import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_tomato/core/database/database.dart';
import 'package:open_tomato/features/journal/data/models/journal_entry_with_details.dart';
import 'package:open_tomato/features/journal/data/repositories/journal_repository.dart';
import 'package:open_tomato/features/journal/domain/enums/entry_type.dart';
import 'package:open_tomato/features/plants/data/repositories/plants_repository.dart';
import 'package:open_tomato/features/plants/domain/enums/start_method.dart';

void main() {
  late AppDatabase db;
  late JournalRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = JournalRepository(db.journalEntriesDao, db.journalPhotosDao);
  });

  tearDown(() => db.close());

  test('create, read, update, delete an entry with nutrient rows and plants',
      () async {
    final plants = PlantsRepository(db.plantsDao);
    final plantId = await plants.createPlant(
      name: 'Roma',
      varietyId: null,
      startDate: DateTime(2026, 7, 1),
      startMethod: StartMethod.seed,
    );

    final id = await repo.createEntry(
      timestamp: DateTime(2026, 9, 1, 8),
      type: EntryType.fertilizing,
      content: '  Fed after watering  ',
      plantIds: [plantId],
      tempF: 74,
      humidityPct: 62,
      nutrientRows: const [
        NutrientLineItemModel(productName: 'Tomato feed', amount: '10 ml'),
        NutrientLineItemModel(productName: '   ', amount: 'ignored'),
      ],
    );

    var details = await repo.getEntryById(id);
    expect(details!.entry.type, EntryType.fertilizing);
    expect(details.entry.content, 'Fed after watering');
    expect(details.plants.single.name, 'Roma');
    expect(details.nutrientRows.single.productName, 'Tomato feed');
    expect(details.entry.tempF, 74);

    await repo.updateEntry(
      entry: JournalEntryModel(
        id: id,
        timestamp: details.entry.timestamp,
        content: 'Edited',
        type: EntryType.note,
        tempF: null,
        humidityPct: null,
        vpdKpa: null,
        soilMoisturePct: null,
        watered: true,
        nutrients: null,
        createdAt: details.entry.createdAt,
        updatedAt: details.entry.updatedAt,
      ),
      plantIds: const [],
      nutrientRows: const [],
    );
    details = await repo.getEntryById(id);
    expect(details!.entry.content, 'Edited');
    expect(details.entry.watered, isTrue);
    expect(details.plants, isEmpty);
    expect(details.nutrientRows, isEmpty);

    final all = await repo.watchAllEntries().first;
    expect(all.length, 1);

    await repo.deleteEntry(id);
    expect(await repo.getEntryById(id), isNull);
  });

  test('entries stream is newest first', () async {
    await repo.createEntry(
      timestamp: DateTime(2026, 8, 1),
      type: EntryType.note,
      content: 'old',
    );
    await repo.createEntry(
      timestamp: DateTime(2026, 8, 3),
      type: EntryType.note,
      content: 'new',
    );
    final all = await repo.watchAllEntries().first;
    expect(all.map((e) => e.entry.content), ['new', 'old']);
  });
}
