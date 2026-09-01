import 'package:flutter/material.dart';

/// Typography scale following iOS design principles
class AppTextStyles {
  static const String fontFamily = 'SF Pro Display'; // iOS default

  // Headings
  static const h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.3,
  );

  static const h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.2,
  );

  static const h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.1,
  );

  // Body
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Labels
  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // Editorial serif accents (bundled; see pubspec fonts section)
  static const String serifFamily = 'Playfair Display';

  static const editorialDisplay = TextStyle(
    fontFamily: serifFamily,
    fontSize: 40,
    fontWeight: FontWeight.w600,
    height: 1.02,
    letterSpacing: -1.2,
  );

  static const editorialTitle = TextStyle(
    fontFamily: serifFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.08,
    letterSpacing: -0.6,
  );

  static const sectionLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 1.5,
    letterSpacing: 1.6,
  );

  static const heroNumeral = TextStyle(
    fontFamily: serifFamily,
    fontSize: 56,
    fontWeight: FontWeight.w600,
    height: 0.9,
    letterSpacing: -1.0,
  );

  static const heroNumeralUnit = TextStyle(
    fontFamily: serifFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  // Special
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  static const overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.6,
    letterSpacing: 1.5,
  );
}
