import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../contracts/timeline_screen_contract.dart';

class TimelineFilterBar extends StatelessWidget {
  const TimelineFilterBar({
    super.key,
    required this.contract,
    required this.selected,
    required this.onChanged,
  });

  final TimelineScreenContract contract;
  final TimelineFilter selected;
  final ValueChanged<TimelineFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        key: const ValueKey('timeline-filters'),
        height: 44,
        decoration: BoxDecoration(
          border: Border.all(color: palette.textSecondary),
          borderRadius: BorderRadius.circular(999),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            for (final filter in TimelineFilter.values)
              Expanded(
                child: _FilterButton(
                  label: filter.label,
                  count: contract.itemCount(filter),
                  selected: selected == filter,
                  onTap: () => onChanged(filter),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textColor =
        selected ? palette.statusOptimalText : palette.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label filter, $count items',
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          color: selected ? palette.statusOptimalFill : Colors.transparent,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: textColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '$count',
                  style: AppTextStyles.labelSmall.copyWith(color: textColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
