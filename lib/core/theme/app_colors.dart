import 'dart:ui';

/// Flat colour constants. Brightness-aware tokens live in [AppPalette]
/// (`app_palette.dart`); prefer those inside widgets.
class AppColors {
  // Primary - leaf greens
  static const primary = Color(0xFF5E9A6A);
  static const primaryDark = Color(0xFF3F7A4C);
  static const primaryLight = Color(0xFF9ED5A3);

  // Secondary - tomato reds and warm soil
  static const secondary = Color(0xFFD64B3C);
  static const secondaryDark = Color(0xFFA3342A);
  static const secondaryLight = Color(0xFFF0A08F);

  // Background
  static const backgroundLight = Color(0xFFF7F4EE);
  static const backgroundDark = Color(0xFF16190F);
  static const surface = Color(0xFFFFFFFF);

  // Text
  static const textPrimary = Color(0xFF2D3436);
  static const textSecondary = Color(0xFF636E72);
  static const textDisabled = Color(0xFFB2BEC3);

  // Semantic colours
  static const success = Color(0xFF6DB383);
  static const warning = Color(0xFFE8A87C);
  static const error = Color(0xFFD75D5D);
  static const info = Color(0xFF7FA4C7);

  // Growth stage colours (see GrowthStage)
  static const stageSeedling = Color(0xFF9ED5A3);
  static const stageVegetative = Color(0xFF5E9A6A);
  static const stageFlowering = Color(0xFFE8C547);
  static const stageFruitSet = Color(0xFF8DBF6E);
  static const stageRipening = Color(0xFFE9873C);
  static const stageHarvesting = Color(0xFFD64B3C);
  static const stageDone = Color(0xFF7A7F78);
  static const stageArchived = Color(0xFF94A3B8);

  // Frosted glass translucent variants
  static const glassPrimary = Color(0xCC5E9A6A);
  static const glassSecondary = Color(0xCCD64B3C);
  static const glassSurface = Color(0xF0FFFFFF);
  static const glassBackground = Color(0xE6F7F4EE);

  // Glass overlay for BackdropFilter
  static const glassOverlay = Color(0x40FFFFFF);
  static const glassOverlayDark = Color(0x30000000);

  // Blur intensities for glass effects
  static const double blurLight = 8.0;
  static const double blurMedium = 16.0;
  static const double blurHeavy = 24.0;
}
