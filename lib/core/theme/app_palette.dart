import 'package:flutter/material.dart';

/// Semantic colour tokens that vary by brightness, resolved via
/// `context.palette`. Keeps widgets from reading flat [AppColors] statics or
/// hardcoding brightness-specific hex values.
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color surface;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;

  final Color statusOptimalFill;
  final Color statusOptimalText;
  final Color statusOptimalBorder;
  final Color statusOptimalShadow;

  final Color statusHighFill;
  final Color statusHighText;
  final Color statusHighBorder;
  final Color statusHighShadow;

  final Color statusLowFill;
  final Color statusLowText;
  final Color statusLowBorder;
  final Color statusLowShadow;

  final Color statusOutOfRangeFill;
  final Color statusOutOfRangeText;
  final Color statusOutOfRangeBorder;
  final Color statusOutOfRangeShadow;

  final Color statusUnstableFill;
  final Color statusUnstableText;
  final Color statusUnstableBorder;
  final Color statusUnstableShadow;

  final Color rangeBarLow;
  final Color rangeBarOptimal;
  final Color rangeBarHigh;
  final Color rangeBarIndicator;

  final Color trendRowFill;
  final Color trendRowBorder;
  final Color chartSurfaceFill;
  final Color chartSurfaceBorder;
  final Color chartGridLine;

  /// Accent used for the hero unit, selected tabs, and chart strokes.
  final Color heroAccent;

  /// Frosted-glass tint for the bottom tab bar's [BackdropFilter] surface.
  /// Keeps the blur effect itself unchanged; only the tint adapts.
  final Color glassSurfaceFill;
  final Color glassSurfaceBorder;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.statusOptimalFill,
    required this.statusOptimalText,
    required this.statusOptimalBorder,
    required this.statusOptimalShadow,
    required this.statusHighFill,
    required this.statusHighText,
    required this.statusHighBorder,
    required this.statusHighShadow,
    required this.statusLowFill,
    required this.statusLowText,
    required this.statusLowBorder,
    required this.statusLowShadow,
    required this.statusOutOfRangeFill,
    required this.statusOutOfRangeText,
    required this.statusOutOfRangeBorder,
    required this.statusOutOfRangeShadow,
    required this.statusUnstableFill,
    required this.statusUnstableText,
    required this.statusUnstableBorder,
    required this.statusUnstableShadow,
    required this.rangeBarLow,
    required this.rangeBarOptimal,
    required this.rangeBarHigh,
    required this.rangeBarIndicator,
    required this.trendRowFill,
    required this.trendRowBorder,
    required this.chartSurfaceFill,
    required this.chartSurfaceBorder,
    required this.chartGridLine,
    required this.heroAccent,
    required this.glassSurfaceFill,
    required this.glassSurfaceBorder,
  });

  static const light = AppPalette(
    background: Color(0xFFF5F3EF),
    surface: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE2DDD1),
    textPrimary: Color(0xFF2D3436),
    textSecondary: Color(0xFF636E72),
    statusOptimalFill: Color(0xFFEAF5E4),
    statusOptimalText: Color(0xFF4C6B3E),
    statusOptimalBorder: Color(0xFFDDE8D6),
    statusOptimalShadow: Color(0x143E6A3F),
    statusHighFill: Color(0xFFFAEFE3),
    statusHighText: Color(0xFF8B603F),
    statusHighBorder: Color(0xFFE7D7C5),
    statusHighShadow: Color(0x1487653F),
    statusLowFill: Color(0xFFF1F2EA),
    statusLowText: Color(0xFF60705D),
    statusLowBorder: Color(0xFFDFE3D7),
    statusLowShadow: Color(0x14606D59),
    statusOutOfRangeFill: Color(0xFFF7EAE6),
    statusOutOfRangeText: Color(0xFF9E5646),
    statusOutOfRangeBorder: Color(0xFFE7D2CA),
    statusOutOfRangeShadow: Color(0x149E5646),
    statusUnstableFill: Color(0xFFF6EEE6),
    statusUnstableText: Color(0xFF8E6447),
    statusUnstableBorder: Color(0xFFE7DAC9),
    statusUnstableShadow: Color(0x148E6447),
    rangeBarLow: Color(0xFFE7E2D6),
    rangeBarOptimal: Color(0xFFCDE0C0),
    rangeBarHigh: Color(0xFFE9D0C4),
    rangeBarIndicator: Color(0xFF2D3436),
    trendRowFill: Color(0xFFF8F5EE),
    trendRowBorder: Color(0xFFE2DDD1),
    chartSurfaceFill: Color(0xFFF8F5EE),
    chartSurfaceBorder: Color(0xFFE2DDD1),
    chartGridLine: Color(0xFFDAD4C7),
    heroAccent: Color(0xFFB8432F),
    glassSurfaceFill: Color(0xF0FFFFFF),
    glassSurfaceBorder: Color(0x1A5E9A6A),
  );

  /// Dark palette: near-black ground, warm accents.
  static const dark = AppPalette(
    background: Color(0xFF14180F),
    surface: Color(0xFF1B2016),
    cardBorder: Color(0xFF2C3324),
    textPrimary: Color(0xFFF3F1E7),
    textSecondary: Color(0xFFA9AC9E),
    statusOptimalFill: Color(0xFF223124),
    statusOptimalText: Color(0xFF8FD98A),
    statusOptimalBorder: Color(0xFF3A5537),
    statusOptimalShadow: Color(0x33000000),
    statusHighFill: Color(0xFF2E2618),
    statusHighText: Color(0xFFE0B583),
    statusHighBorder: Color(0xFF463A24),
    statusHighShadow: Color(0x33000000),
    statusLowFill: Color(0xFF1D2622),
    statusLowText: Color(0xFF9BB8AC),
    statusLowBorder: Color(0xFF32403A),
    statusLowShadow: Color(0x33000000),
    statusOutOfRangeFill: Color(0xFF2E211C),
    statusOutOfRangeText: Color(0xFFE0A08C),
    statusOutOfRangeBorder: Color(0xFF473229),
    statusOutOfRangeShadow: Color(0x33000000),
    statusUnstableFill: Color(0xFF2B2419),
    statusUnstableText: Color(0xFFDBB98C),
    statusUnstableBorder: Color(0xFF453A29),
    statusUnstableShadow: Color(0x33000000),
    rangeBarLow: Color(0xFF3A3A2E),
    rangeBarOptimal: Color(0xFF7C8A4A),
    rangeBarHigh: Color(0xFF4A3A2E),
    rangeBarIndicator: Color(0xFFF3F1E7),
    trendRowFill: Color(0xFF1F2419),
    trendRowBorder: Color(0xFF2C3324),
    chartSurfaceFill: Color(0xFF1F2419),
    chartSurfaceBorder: Color(0xFF2C3324),
    chartGridLine: Color(0xFF333B29),
    heroAccent: Color(0xFFE8654F),
    glassSurfaceFill: Color(0xE6161A11),
    glassSurfaceBorder: Color(0x337C8A4A),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? cardBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? statusOptimalFill,
    Color? statusOptimalText,
    Color? statusOptimalBorder,
    Color? statusOptimalShadow,
    Color? statusHighFill,
    Color? statusHighText,
    Color? statusHighBorder,
    Color? statusHighShadow,
    Color? statusLowFill,
    Color? statusLowText,
    Color? statusLowBorder,
    Color? statusLowShadow,
    Color? statusOutOfRangeFill,
    Color? statusOutOfRangeText,
    Color? statusOutOfRangeBorder,
    Color? statusOutOfRangeShadow,
    Color? statusUnstableFill,
    Color? statusUnstableText,
    Color? statusUnstableBorder,
    Color? statusUnstableShadow,
    Color? rangeBarLow,
    Color? rangeBarOptimal,
    Color? rangeBarHigh,
    Color? rangeBarIndicator,
    Color? trendRowFill,
    Color? trendRowBorder,
    Color? chartSurfaceFill,
    Color? chartSurfaceBorder,
    Color? chartGridLine,
    Color? heroAccent,
    Color? glassSurfaceFill,
    Color? glassSurfaceBorder,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      cardBorder: cardBorder ?? this.cardBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      statusOptimalFill: statusOptimalFill ?? this.statusOptimalFill,
      statusOptimalText: statusOptimalText ?? this.statusOptimalText,
      statusOptimalBorder: statusOptimalBorder ?? this.statusOptimalBorder,
      statusOptimalShadow: statusOptimalShadow ?? this.statusOptimalShadow,
      statusHighFill: statusHighFill ?? this.statusHighFill,
      statusHighText: statusHighText ?? this.statusHighText,
      statusHighBorder: statusHighBorder ?? this.statusHighBorder,
      statusHighShadow: statusHighShadow ?? this.statusHighShadow,
      statusLowFill: statusLowFill ?? this.statusLowFill,
      statusLowText: statusLowText ?? this.statusLowText,
      statusLowBorder: statusLowBorder ?? this.statusLowBorder,
      statusLowShadow: statusLowShadow ?? this.statusLowShadow,
      statusOutOfRangeFill: statusOutOfRangeFill ?? this.statusOutOfRangeFill,
      statusOutOfRangeText: statusOutOfRangeText ?? this.statusOutOfRangeText,
      statusOutOfRangeBorder:
          statusOutOfRangeBorder ?? this.statusOutOfRangeBorder,
      statusOutOfRangeShadow:
          statusOutOfRangeShadow ?? this.statusOutOfRangeShadow,
      statusUnstableFill: statusUnstableFill ?? this.statusUnstableFill,
      statusUnstableText: statusUnstableText ?? this.statusUnstableText,
      statusUnstableBorder: statusUnstableBorder ?? this.statusUnstableBorder,
      statusUnstableShadow: statusUnstableShadow ?? this.statusUnstableShadow,
      rangeBarLow: rangeBarLow ?? this.rangeBarLow,
      rangeBarOptimal: rangeBarOptimal ?? this.rangeBarOptimal,
      rangeBarHigh: rangeBarHigh ?? this.rangeBarHigh,
      rangeBarIndicator: rangeBarIndicator ?? this.rangeBarIndicator,
      trendRowFill: trendRowFill ?? this.trendRowFill,
      trendRowBorder: trendRowBorder ?? this.trendRowBorder,
      chartSurfaceFill: chartSurfaceFill ?? this.chartSurfaceFill,
      chartSurfaceBorder: chartSurfaceBorder ?? this.chartSurfaceBorder,
      chartGridLine: chartGridLine ?? this.chartGridLine,
      heroAccent: heroAccent ?? this.heroAccent,
      glassSurfaceFill: glassSurfaceFill ?? this.glassSurfaceFill,
      glassSurfaceBorder: glassSurfaceBorder ?? this.glassSurfaceBorder,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      statusOptimalFill:
          Color.lerp(statusOptimalFill, other.statusOptimalFill, t)!,
      statusOptimalText:
          Color.lerp(statusOptimalText, other.statusOptimalText, t)!,
      statusOptimalBorder:
          Color.lerp(statusOptimalBorder, other.statusOptimalBorder, t)!,
      statusOptimalShadow:
          Color.lerp(statusOptimalShadow, other.statusOptimalShadow, t)!,
      statusHighFill: Color.lerp(statusHighFill, other.statusHighFill, t)!,
      statusHighText: Color.lerp(statusHighText, other.statusHighText, t)!,
      statusHighBorder:
          Color.lerp(statusHighBorder, other.statusHighBorder, t)!,
      statusHighShadow:
          Color.lerp(statusHighShadow, other.statusHighShadow, t)!,
      statusLowFill: Color.lerp(statusLowFill, other.statusLowFill, t)!,
      statusLowText: Color.lerp(statusLowText, other.statusLowText, t)!,
      statusLowBorder: Color.lerp(statusLowBorder, other.statusLowBorder, t)!,
      statusLowShadow: Color.lerp(statusLowShadow, other.statusLowShadow, t)!,
      statusOutOfRangeFill:
          Color.lerp(statusOutOfRangeFill, other.statusOutOfRangeFill, t)!,
      statusOutOfRangeText:
          Color.lerp(statusOutOfRangeText, other.statusOutOfRangeText, t)!,
      statusOutOfRangeBorder: Color.lerp(
        statusOutOfRangeBorder,
        other.statusOutOfRangeBorder,
        t,
      )!,
      statusOutOfRangeShadow: Color.lerp(
        statusOutOfRangeShadow,
        other.statusOutOfRangeShadow,
        t,
      )!,
      statusUnstableFill:
          Color.lerp(statusUnstableFill, other.statusUnstableFill, t)!,
      statusUnstableText:
          Color.lerp(statusUnstableText, other.statusUnstableText, t)!,
      statusUnstableBorder:
          Color.lerp(statusUnstableBorder, other.statusUnstableBorder, t)!,
      statusUnstableShadow:
          Color.lerp(statusUnstableShadow, other.statusUnstableShadow, t)!,
      rangeBarLow: Color.lerp(rangeBarLow, other.rangeBarLow, t)!,
      rangeBarOptimal: Color.lerp(rangeBarOptimal, other.rangeBarOptimal, t)!,
      rangeBarHigh: Color.lerp(rangeBarHigh, other.rangeBarHigh, t)!,
      rangeBarIndicator:
          Color.lerp(rangeBarIndicator, other.rangeBarIndicator, t)!,
      trendRowFill: Color.lerp(trendRowFill, other.trendRowFill, t)!,
      trendRowBorder: Color.lerp(trendRowBorder, other.trendRowBorder, t)!,
      chartSurfaceFill:
          Color.lerp(chartSurfaceFill, other.chartSurfaceFill, t)!,
      chartSurfaceBorder:
          Color.lerp(chartSurfaceBorder, other.chartSurfaceBorder, t)!,
      chartGridLine: Color.lerp(chartGridLine, other.chartGridLine, t)!,
      heroAccent: Color.lerp(heroAccent, other.heroAccent, t)!,
      glassSurfaceFill:
          Color.lerp(glassSurfaceFill, other.glassSurfaceFill, t)!,
      glassSurfaceBorder:
          Color.lerp(glassSurfaceBorder, other.glassSurfaceBorder, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
