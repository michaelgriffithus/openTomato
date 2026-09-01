import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../../domain/helpers/event_type_helper.dart';
import '../contracts/timeline_screen_contract.dart';
import '../widgets/global_capture_sheet.dart';
import '../widgets/journal_calendar_view.dart';
import '../widgets/timeline_filter_bar.dart';

abstract interface class TimelineScreenActions {
  void addEntry();
  void openItem(TimelineItemContract item);
  void openTasks();
  void refresh();
}

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  TimelineFilter _filter = TimelineFilter.all;
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return TimelineScreenView(
      contract: ref.watch(timelineScreenContractProvider),
      filter: _filter,
      selectedDay: _selectedDay,
      onFilterChanged: (filter) => setState(() => _filter = filter),
      onDayTapped: (day) => setState(() {
        final current = _selectedDay;
        _selectedDay = current != null &&
                current.year == day.year &&
                current.month == day.month &&
                current.day == day.day
            ? null
            : day;
      }),
      actions: _Actions(context, ref),
    );
  }
}

/// Provider-free view.
class TimelineScreenView extends StatelessWidget {
  const TimelineScreenView({
    super.key,
    required this.contract,
    required this.filter,
    required this.selectedDay,
    required this.onFilterChanged,
    required this.onDayTapped,
    required this.actions,
  });

  final TimelineScreenContract contract;
  final TimelineFilter filter;
  final DateTime? selectedDay;
  final ValueChanged<TimelineFilter> onFilterChanged;
  final ValueChanged<DateTime> onDayTapped;
  final TimelineScreenActions actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppScreenHeader(
              eyebrow: 'Journal',
              title: 'Timeline',
              action: IconButton(
                tooltip: 'Tasks',
                onPressed: actions.openTasks,
                icon: const Icon(Icons.checklist_outlined),
              ),
            ),
            Expanded(child: _body(context)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    return switch (contract.phase) {
      TimelineScreenPhase.loading =>
        const Center(child: CircularProgressIndicator.adaptive()),
      TimelineScreenPhase.empty => AppEmptyState(
          icon: Icons.schedule_outlined,
          title: 'Your journal starts here',
          body: 'Log watering, feeding, photos, and notes. Each entry can '
              'carry the readings from your grow space.',
          actionLabel: 'Add first entry',
          onAction: actions.addEntry,
        ),
      TimelineScreenPhase.error => AppEmptyState(
          icon: Icons.sync_problem_outlined,
          title: 'Journal could not load',
          body: contract.errorMessage ?? 'Something went wrong.',
          actionLabel: 'Try again',
          onAction: actions.refresh,
        ),
      TimelineScreenPhase.ready => _Ready(
          contract: contract,
          filter: filter,
          selectedDay: selectedDay,
          onFilterChanged: onFilterChanged,
          onDayTapped: onDayTapped,
          actions: actions,
        ),
    };
  }
}

class _Ready extends StatelessWidget {
  const _Ready({
    required this.contract,
    required this.filter,
    required this.selectedDay,
    required this.onFilterChanged,
    required this.onDayTapped,
    required this.actions,
  });

  final TimelineScreenContract contract;
  final TimelineFilter filter;
  final DateTime? selectedDay;
  final ValueChanged<TimelineFilter> onFilterChanged;
  final ValueChanged<DateTime> onDayTapped;
  final TimelineScreenActions actions;

  @override
  Widget build(BuildContext context) {
    final sections = contract.visibleSections(filter, day: selectedDay);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: JournalCalendarView(
            datesWithEntries: contract.daysWithEntries,
            datesWithTodos: contract.daysWithTasks,
            selectedDate: selectedDay,
            onDateTapped: onDayTapped,
          ),
        ),
        TimelineFilterBar(
          contract: contract,
          selected: filter,
          onChanged: onFilterChanged,
        ),
        Expanded(
          child: sections.isEmpty
              ? AppEmptyState(
                  icon: Icons.filter_alt_off_outlined,
                  title: 'Nothing here',
                  body: selectedDay == null
                      ? 'Choose another filter or add an entry.'
                      : 'Nothing logged on ${DateFormat('MMM d').format(selectedDay!)}.',
                  actionLabel: 'Add entry',
                  onAction: actions.addEntry,
                  secondaryLabel: 'Show everything',
                  onSecondary: () {
                    onFilterChanged(TimelineFilter.all);
                    if (selectedDay != null) onDayTapped(selectedDay!);
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                  itemCount: sections.length,
                  itemBuilder: (context, index) =>
                      _Day(section: sections[index], actions: actions),
                ),
        ),
      ],
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.section, required this.actions});

  final TimelineDayContract section;
  final TimelineScreenActions actions;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.label,
            style: AppTextStyles.sectionLabel.copyWith(
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in section.items) _Row(item: item, actions: actions),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.actions});

  final TimelineItemContract item;
  final TimelineScreenActions actions;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = item.type == null
        ? palette.statusHighText
        : EventTypeHelper.getColor(item.type!);
    return InkWell(
      onTap: () => actions.openItem(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 48,
              child: Text(
                item.kind == TimelineItemKind.task
                    ? 'due'
                    : DateFormat('H:mm').format(item.timestamp),
                style: AppTextStyles.bodySmall.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.type?.icon ?? Icons.task_alt,
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.photoCount > 0
                        ? '${item.detail} · ${item.photoCount} photo${item.photoCount == 1 ? '' : 's'}'
                        : item.detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Actions implements TimelineScreenActions {
  _Actions(this.context, this.ref);

  final BuildContext context;
  final WidgetRef ref;

  @override
  void addEntry() => openGlobalCaptureFlow(context);

  @override
  void openItem(TimelineItemContract item) {
    if (item.journalEntryId != null) {
      context.push('/timeline/${item.journalEntryId}');
    } else {
      context.push('/timeline/tasks');
    }
  }

  @override
  void openTasks() => context.push('/timeline/tasks');

  @override
  void refresh() => ref.invalidate(journalTimelineEntriesProviderRef);
}

// Indirection keeps the invalidate target in one place.
final journalTimelineEntriesProviderRef = timelineScreenContractProvider;
