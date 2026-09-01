import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// How old a stored environment reading can be and still be presented as the
/// "current reading". Surfaces that show history (charts, time-in-range)
/// intentionally ignore this.
const Duration environmentSnapshotFreshness = Duration(hours: 2);

double? parseTemperatureToF(String? raw) {
  if (raw == null) {
    return null;
  }

  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }

  final compact = normalized.replaceAll('°', '').replaceAll(' ', '');
  final match = RegExp(r'^(-?\d+(?:\.\d+)?)([fc])?$').firstMatch(compact);
  if (match == null) {
    debugPrint('Unable to parse temperature reading: $raw');
    return null;
  }

  final parsed = double.tryParse(match.group(1)!);
  if (parsed == null) {
    debugPrint('Unable to parse temperature reading: $raw');
    return null;
  }

  final unit = match.group(2);
  final fahrenheit = unit == 'c' ? (parsed * 9 / 5) + 32 : parsed;
  return sanitizeTemperatureF(fahrenheit);
}

/// Plausible air temperature for a grow space. Anything outside is treated as
/// a mis-mapped entity (a CPU temperature, a freezer probe) rather than data.
double? sanitizeTemperatureF(double? value) {
  if (value == null || !value.isFinite) {
    return null;
  }
  if (value < 35 || value > 120) {
    return null;
  }
  return value;
}

double? sanitizeHumidityPct(double? value) {
  if (value == null || !value.isFinite) {
    return null;
  }
  if (value < 0 || value > 100) {
    return null;
  }
  return value;
}

double? sanitizeVpdKpa(double? value) {
  if (value == null || !value.isFinite) {
    return null;
  }
  if (value < 0 || value > 10) {
    return null;
  }
  return value;
}

double? sanitizeSoilMoisturePct(double? value) => sanitizeHumidityPct(value);

/// Canonical air-VPD (kPa): the single source of truth for every VPD value
/// derived in the app. Every ingest path delegates here so values cannot
/// drift apart.
///
/// This is **air** VPD: saturation vapour pressure from the Tetens equation
/// scaled by `(1 − RH/100)`. There is no leaf-temperature term anywhere.
///
/// Returns `null` when inputs are missing or the result is outside the
/// plausible range guarded by [sanitizeVpdKpa].
double? vpdKpaFromCelsius(double? tempC, double? rhPct) {
  if (tempC == null || rhPct == null || !tempC.isFinite || !rhPct.isFinite) {
    return null;
  }
  final vpd =
      saturationVapourPressureKpaFromCelsius(tempC) * (1.0 - rhPct / 100.0);
  return sanitizeVpdKpa(vpd);
}

/// Tetens saturation vapour pressure (kPa) over water.
double saturationVapourPressureKpaFromCelsius(double tempC) {
  return 0.6108 * math.exp((17.27 * tempC) / (tempC + 237.3));
}

double? saturationVapourPressureKpaFromFahrenheit(double? tempF) {
  if (tempF == null || !tempF.isFinite) {
    return null;
  }
  return saturationVapourPressureKpaFromCelsius((tempF - 32) * 5 / 9);
}

/// Convenience wrapper around [vpdKpaFromCelsius] for Fahrenheit inputs.
double? vpdKpaFromFahrenheit(double? tempF, double? rhPct) {
  if (tempF == null || !tempF.isFinite) {
    return null;
  }
  return vpdKpaFromCelsius((tempF - 32) * 5 / 9, rhPct);
}

double fahrenheitToCelsius(double tempF) => (tempF - 32) * 5 / 9;

double celsiusToFahrenheit(double tempC) => tempC * 9 / 5 + 32;
