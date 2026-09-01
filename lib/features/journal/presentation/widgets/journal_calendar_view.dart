import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';

/// Compact horizontal strip of days, two weeks back and three ahead, with
/// dots for days that have entries or tasks.
class JournalCalendarView extends StatefulWidget {
  final Set<DateTime> datesWithEntries;
  final Set<DateTime> datesWithTodos;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateTapped;

  const JournalCalendarView({
    super.key,
    required this.datesWithEntries,
    this.datesWithTodos = const {},
    this.selectedDate,
    required this.onDateTapped,
  });

  @override
  State<JournalCalendarView> createState() => _JournalCalendarViewState();
}

class _JournalCalendarViewState extends State<JournalCalendarView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    if (!_scrollController.hasClients) return;
    final daysSinceStart = DateTime.now().difference(_startDate).inDays;
    final offset =
        daysSinceStart * 54.0 - (MediaQuery.of(context).size.width / 2) + 27;
    final target =
        offset.clamp(0, _scrollController.position.maxScrollExtent).toDouble();
    if (MediaQuery.disableAnimationsOf(context)) {
      _scrollController.jumpTo(target);
    } else {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  DateTime get _startDate => DateTime.now().subtract(const Duration(days: 14));
  DateTime get _endDate => DateTime.now().add(const Duration(days: 21));

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final totalDays = _endDate.difference(_startDate).inDays + 1;
    final now = DateTime.now();

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.textDisabled.withValues(alpha: 0.2)),
      ),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: totalDays,
        itemBuilder: (context, index) {
          final date = _startDate.add(Duration(days: index));
          final hasEntry =
              widget.datesWithEntries.any((d) => _sameDay(d, date));
          final hasTodo = widget.datesWithTodos.any((d) => _sameDay(d, date));
          final selected = widget.selectedDate;
          final isSelected = selected != null && _sameDay(date, selected);
          final isToday = _sameDay(date, now) && selected == null;
          final highlight = isToday || isSelected;
          return Semantics(
            button: true,
            selected: highlight,
            label: '${_weekday(date.weekday)} ${date.day}'
                '${hasEntry ? ', has entries' : ''}'
                '${hasTodo ? ', has tasks' : ''}',
            child: GestureDetector(
              onTap: () => widget.onDateTapped(date),
              child: Container(
                width: 50,
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: highlight
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : null,
                  border: highlight
                      ? Border.all(
                          color: AppColors.primary,
                          width: isSelected ? 2 : 1,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _weekday(date.weekday),
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 8,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        color:
                            highlight ? AppColors.primary : palette.textPrimary,
                        fontWeight:
                            highlight ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                    if (hasEntry || hasTodo)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (hasEntry) _dot(AppColors.primary),
                            if (hasEntry && hasTodo) const SizedBox(width: 3),
                            if (hasTodo) _dot(AppColors.secondary),
                          ],
                        ),
                      )
                    else
                      const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  String _weekday(int weekday) =>
      const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][weekday - 1];
}
