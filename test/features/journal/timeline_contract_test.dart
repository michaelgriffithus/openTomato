import 'package:flutter_test/flutter_test.dart';
import 'package:open_tomato/core/database/database.dart';
import 'package:open_tomato/features/journal/data/models/journal_entry_with_details.dart';
import 'package:open_tomato/features/journal/domain/enums/entry_type.dart';
import 'package:open_tomato/features/journal/domain/services/journal_capture_validation.dart';
import 'package:open_tomato/features/journal/presentation/contracts/timeline_screen_contract.dart';
import 'package:open_tomato/features/plants/domain/enums/growth_stage.dart';
import 'package:open_tomato/features/plants/domain/enums/start_method.dart';
import 'package:open_tomato/features/plants/domain/models/plant_model.dart';

PlantModel _plant(String name) => PlantModel(
      id: name.hashCode,
      name: name,
      varietyId: null,
      startDate: DateTime(2026, 7, 1),
      startMethod: StartMethod.seed,
      stage: GrowthStage.vegetative,
      stageStartedAt: null,
      growSpaceId: null,
      location: null,
      container: null,
      medium: null,
      notes: null,
      harvestedAt: null,
      harvestNotes: null,
      createdAt: DateTime(2026, 7, 1),
      archivedAt: null,
    );

JournalEntryWithPlantsAndPhotos _entry({
  required int id,
  required DateTime at,
  required EntryType type,
  String? content,
  List<PlantModel> plants = const [],
  bool watered = false,
  double? tempF,
}) =>
    JournalEntryWithPlantsAndPhotos(
      entry: JournalEntryModel(
        id: id,
        timestamp: at,
        content: content,
        type: type,
        tempF: tempF,
        humidityPct: null,
        vpdKpa: null,
        soilMoisturePct: null,
        watered: watered,
        nutrients: null,
        createdAt: at,
        updatedAt: at,
      ),
      photos: const [],
      plants: plants,
    );

void main() {
  final now = DateTime(2026, 9, 1, 12);

  test('empty', () {
    final c =
        buildTimelineContract(entries: const [], todos: const [], now: now);
    expect(c.phase, TimelineScreenPhase.empty);
  });

  test('groups by day with TODAY/YESTERDAY/UPCOMING labels, newest first', () {
    final c = buildTimelineContract(
      entries: [
        _entry(
          id: 1,
          at: DateTime(2026, 9, 1, 8),
          type: EntryType.note,
          content: 'Today note',
        ),
        _entry(
          id: 2,
          at: DateTime(2026, 8, 31, 8),
          type: EntryType.watering,
          plants: [_plant('Roma')],
        ),
        _entry(id: 3, at: DateTime(2026, 8, 20, 8), type: EntryType.photo),
      ],
      todos: [
        TodoItemWithPlant(
          todo: TodoItem(
            id: 9,
            title: 'Tie up',
            dueDate: DateTime(2026, 9, 3),
            priority: 2,
            status: 'pending',
            sourceType: 'manual',
            isRecurring: false,
            createdAt: now,
            updatedAt: now,
          ),
          plant: null,
        ),
      ],
      now: now,
    );
    expect(c.phase, TimelineScreenPhase.ready);
    expect(
      c.sections.map((s) => s.label),
      ['UPCOMING · SEP 3', 'TODAY', 'YESTERDAY', 'AUG 20'],
    );
    expect(c.sections[2].items.single.title, 'Roma watered');
    expect(c.sections[1].items.single.title, 'Today note');
    expect(c.itemCount(TimelineFilter.care), 1);
    expect(c.itemCount(TimelineFilter.notes), 2);
    expect(c.itemCount(TimelineFilter.tasks), 1);
    expect(c.daysWithTasks, {DateTime(2026, 9, 3)});
    expect(
      c.visibleSections(TimelineFilter.all, day: DateTime(2026, 8, 31)).length,
      1,
    );
  });

  test('a note with readings shows them in the detail', () {
    final item = journalTimelineItem(
      _entry(
        id: 1,
        at: now,
        type: EntryType.inspect,
        plants: [_plant('Roma')],
        tempF: 77.6,
      ),
    );
    expect(item.title, 'Roma inspected');
    expect(item.detail, contains('78 °F'));
    expect(item.kind, TimelineItemKind.observation);
  });

  group('capture validation', () {
    JournalCaptureValidationInput input(
      EntryType type, {
      String content = '',
      int photos = 0,
      List<String> products = const [],
      bool readings = false,
    }) =>
        JournalCaptureValidationInput(
          type: type,
          content: content,
          photoCount: photos,
          nutrientProductNames: products,
          hasReadings: readings,
        );

    test('photo entry needs a photo', () {
      expect(validateJournalCapture(input(EntryType.photo)).isValid, isFalse);
      expect(
        validateJournalCapture(input(EntryType.photo, photos: 1)).isValid,
        isTrue,
      );
    });
    test('feeding needs a product or a note', () {
      expect(
        validateJournalCapture(input(EntryType.fertilizing, products: [' ']))
            .isValid,
        isFalse,
      );
      expect(
        validateJournalCapture(
          input(EntryType.fertilizing, products: ['Feed']),
        ).isValid,
        isTrue,
      );
    });
    test('watering is always valid; stage change never', () {
      expect(validateJournalCapture(input(EntryType.watering)).isValid, isTrue);
      expect(
        validateJournalCapture(input(EntryType.stageChange, content: 'x'))
            .isValid,
        isFalse,
      );
    });
    test('inspection accepts readings alone', () {
      expect(validateJournalCapture(input(EntryType.inspect)).isValid, isFalse);
      expect(
        validateJournalCapture(input(EntryType.inspect, readings: true))
            .isValid,
        isTrue,
      );
    });
  });
}
