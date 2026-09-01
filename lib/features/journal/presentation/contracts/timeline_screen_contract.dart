import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/database.dart';
import '../../../todos/presentation/providers/todo_providers.dart';
import '../../data/models/journal_entry_with_details.dart';
import '../../domain/enums/entry_type.dart';
import '../../domain/helpers/event_type_helper.dart';
import '../providers/journal_providers.dart';

enum TimelineScreenPhase { loading, ready, empty, error }

enum TimelineItemKind { care, observation, task }

enum TimelineFilter {
  all('All'),
  care('Care'),
  notes('Notes'),
  tasks('Tasks');

  const TimelineFilter(this.label);

  final String label;

  bool accepts(TimelineItemKind kind) => switch (this) {
        TimelineFilter.all => true,
        TimelineFilter.care => kind == TimelineItemKind.care,
        TimelineFilter.notes => kind == TimelineItemKind.observation,
        TimelineFilter.tasks => kind == TimelineItemKind.task,
      };
}

class TimelineItemContract {
  const TimelineItemContract({
    required this.id,
    required this.timestamp,
    required this.kind,
    required this.type,
    required this.title,
    required this.detail,
    required this.photoCount,
    this.journalEntryId,
    this.todoId,
  });

  final String id;
  final DateTime timestamp;
  final TimelineItemKind kind;
  final EntryType? type;
  final String title;
  final String detail;
  final int photoCount;
  final int? journalEntryId;
  final int? todoId;
}

class TimelineDayContract {
  const TimelineDayContract({
    required this.day,
    required this.label,
    required this.items,
  });

  final DateTime day;
  final String label;
  final List<TimelineItemContract> items;
}

class TimelineScreenContract {
  const TimelineScreenContract({
    required this.phase,
    required this.sections,
    this.errorMessage,
  });

  final TimelineScreenPhase phase;
  final List<TimelineDayContract> sections;
  final String? errorMessage;

  static const loading =
      TimelineScreenContract(phase: TimelineScreenPhase.loading, sections: []);

  List<TimelineDayContract> visibleSections(
    TimelineFilter filter, {
    DateTime? day,
  }) {
    return [
      for (final section in sections)
        if (day == null || _sameDay(section.day, day))
          if (section.items.any((item) => filter.accepts(item.kind)))
            TimelineDayContract(
              day: section.day,
              label: section.label,
              items: section.items
                  .where((item) => filter.accepts(item.kind))
                  .toList(growable: false),
            ),
    ];
  }

  int itemCount(TimelineFilter filter) => visibleSections(filter)
      .fold(0, (count, section) => count + section.items.length);

  Set<DateTime> get daysWithEntries => {
        for (final section in sections)
          if (section.items.any((i) => i.kind != TimelineItemKind.task))
            section.day,
      };

  Set<DateTime> get daysWithTasks => {
        for (final section in sections)
          if (section.items.any((i) => i.kind == TimelineItemKind.task))
            section.day,
      };
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

final timelineScreenContractProvider = Provider<TimelineScreenContract>((ref) {
  final entries = ref.watch(journalTimelineEntriesProvider);
  final todos = ref.watch(activeTodosProvider);
  if (!entries.hasValue && entries.isLoading) {
    return TimelineScreenContract.loading;
  }
  if (entries.hasError && !entries.hasValue) {
    return TimelineScreenContract(
      phase: TimelineScreenPhase.error,
      sections: const [],
      errorMessage: 'Could not load the journal: ${entries.error}',
    );
  }
  return buildTimelineContract(
    entries: entries.valueOrNull ?? const [],
    todos: todos.valueOrNull ?? const [],
  );
});

TimelineScreenContract buildTimelineContract({
  required List<JournalEntryWithPlantsAndPhotos> entries,
  required List<TodoItemWithPlant> todos,
  DateTime? now,
}) {
  final items = <TimelineItemContract>[
    for (final record in entries) journalTimelineItem(record),
    for (final todo in todos) todoTimelineItem(todo),
  ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  if (items.isEmpty) {
    return const TimelineScreenContract(
      phase: TimelineScreenPhase.empty,
      sections: [],
    );
  }
  return TimelineScreenContract(
    phase: TimelineScreenPhase.ready,
    sections: timelineSections(items, now ?? DateTime.now()),
  );
}

TimelineItemContract journalTimelineItem(
  JournalEntryWithPlantsAndPhotos record,
) {
  final entry = record.entry;
  final names = record.plants.map((plant) => plant.name).join(' + ');
  final firstLine = entry.content?.trim().split('\n').firstOrNull;
  final title = switch (entry.type) {
    EntryType.note ||
    EntryType.stageChange ||
    EntryType.harvest when firstLine != null && firstLine.isNotEmpty =>
      firstLine,
    _ => names.isEmpty
        ? entry.type.displayName
        : '$names ${EventTypeHelper.getVerb(entry.type)}',
  };
  final detailParts = <String>[
    if (names.isNotEmpty && title != names) names,
    if (entry.tempF != null) '${entry.tempF!.round()} °F',
    if (entry.humidityPct != null) '${entry.humidityPct!.round()} % RH',
    if (firstLine != null && firstLine.isNotEmpty && title != firstLine)
      firstLine,
  ];
  final isCare = switch (entry.type) {
    EntryType.watering ||
    EntryType.fertilizing ||
    EntryType.pruning ||
    EntryType.staking ||
    EntryType.transplanting =>
      true,
    _ => entry.watered,
  };
  return TimelineItemContract(
    id: 'journal:${entry.id}',
    timestamp: entry.timestamp,
    kind: isCare ? TimelineItemKind.care : TimelineItemKind.observation,
    type: entry.type,
    title: title,
    detail:
        detailParts.isEmpty ? entry.type.displayName : detailParts.join(' · '),
    photoCount: record.photos.length,
    journalEntryId: entry.id,
  );
}

TimelineItemContract todoTimelineItem(TodoItemWithPlant record) {
  return TimelineItemContract(
    id: 'todo:${record.todo.id}',
    timestamp: record.todo.dueDate,
    kind: TimelineItemKind.task,
    type: null,
    title: record.todo.title,
    detail: record.plant?.name ?? record.todo.description ?? 'Task',
    photoCount: 0,
    todoId: record.todo.id,
  );
}

List<TimelineDayContract> timelineSections(
  List<TimelineItemContract> items,
  DateTime now,
) {
  final grouped = <DateTime, List<TimelineItemContract>>{};
  for (final item in items) {
    final day =
        DateTime(item.timestamp.year, item.timestamp.month, item.timestamp.day);
    grouped.putIfAbsent(day, () => []).add(item);
  }
  final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
  final today = DateTime(now.year, now.month, now.day);
  return [
    for (final day in days)
      TimelineDayContract(
        day: day,
        label: day == today
            ? 'TODAY'
            : day == today.subtract(const Duration(days: 1))
                ? 'YESTERDAY'
                : day.isAfter(today)
                    ? 'UPCOMING · ${DateFormat('MMM d').format(day).toUpperCase()}'
                    : DateFormat('MMM d').format(day).toUpperCase(),
        items: grouped[day]!,
      ),
  ];
}
