import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';

/// A date and time picker with glass styling
///
/// Provides consistent picker appearance with:
/// - Glass-effect border
/// - Optional date, time, or both
/// - Formatted display
/// - Validation support
class GlassDateTimePicker extends StatelessWidget {
  final DateTime? value;
  final String? labelText;
  final String? errorText;
  final void Function(DateTime) onChanged;
  final DateTimePickerMode mode;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;

  const GlassDateTimePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelText,
    this.errorText,
    this.mode = DateTimePickerMode.dateOnly,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    return InkWell(
      onTap: enabled ? () => _showPicker(context) : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          errorText: errorText,
          suffixIcon: Icon(
            mode == DateTimePickerMode.dateOnly
                ? Icons.calendar_today
                : mode == DateTimePickerMode.timeOnly
                    ? Icons.access_time
                    : Icons.event,
            size: 20,
            color: enabled ? AppColors.primary : AppColors.textDisabled,
          ),

          // Glass effect border
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.textDisabled.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.error.withValues(alpha: 0.5),
              width: 1,
            ),
          ),

          // Glass background
          filled: true,
          fillColor: enabled
              ? colors.surface.withValues(alpha: 0.8)
              : colors.surface.withValues(alpha: 0.4),

          // Label styling
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),

          // Padding
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        child: Text(
          _formatDateTime(value),
          style: AppTextStyles.bodyMedium.copyWith(
            color: enabled
                ? (value != null ? colors.textPrimary : AppColors.textDisabled)
                : AppColors.textDisabled,
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return mode == DateTimePickerMode.dateOnly
          ? 'Tap to select date'
          : mode == DateTimePickerMode.timeOnly
              ? 'Tap to select time'
              : 'Tap to select date & time';
    }

    switch (mode) {
      case DateTimePickerMode.dateOnly:
        return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
      case DateTimePickerMode.timeOnly:
        final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
        final period = dateTime.hour >= 12 ? 'PM' : 'AM';
        return '${hour == 0 ? 12 : hour}:${dateTime.minute.toString().padLeft(2, '0')} $period';
      case DateTimePickerMode.dateAndTime:
        final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
        final period = dateTime.hour >= 12 ? 'PM' : 'AM';
        return '${dateTime.month}/${dateTime.day}/${dateTime.year} '
            '${hour == 0 ? 12 : hour}:${dateTime.minute.toString().padLeft(2, '0')} $period';
    }
  }

  Future<void> _showPicker(BuildContext context) async {
    DateTime? selectedDate = value ?? DateTime.now();

    // Show date picker if needed
    if (mode == DateTimePickerMode.dateOnly ||
        mode == DateTimePickerMode.dateAndTime) {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: firstDate ?? DateTime(2000),
        lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppColors.primary,
                  ),
            ),
            child: child!,
          );
        },
      );

      if (pickedDate == null) return;
      selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        selectedDate.hour,
        selectedDate.minute,
      );
    }

    // Show time picker if needed
    if (mode == DateTimePickerMode.timeOnly ||
        mode == DateTimePickerMode.dateAndTime) {
      if (!context.mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppColors.primary,
                  ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime == null) return;
      selectedDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    }

    onChanged(selectedDate);
  }
}

enum DateTimePickerMode {
  dateOnly,
  timeOnly,
  dateAndTime,
}
