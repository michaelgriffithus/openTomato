import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_palette.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      colors: AppPalette.light,
      primary: AppColors.primaryDark,
    );
  }

  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      colors: AppPalette.dark,
      primary: AppPalette.dark.heroAccent,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required AppPalette colors,
    required Color primary,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: primary,
      secondary: colors.heroAccent,
      surface: colors.surface,
      error: AppColors.error,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.cardBorder),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: Colors.transparent,
        indicatorColor: colors.rangeBarOptimal.withValues(alpha: 0.45),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? colors.heroAccent
                : colors.textSecondary,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.heroAccent
                : colors.textSecondary,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.cardBorder,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: colors.surface,
        modalBackgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      extensions: [colors],
    );
  }
}
