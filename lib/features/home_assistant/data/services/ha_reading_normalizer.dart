import '../../../../core/utils/environment_readings.dart';
import '../models/ha_entity_state.dart';

/// Turns raw entity states into canonical units: °F, %, kPa. The one place
/// that knows about unit strings.
class HAReadingNormalizer {
  const HAReadingNormalizer();

  static const double psiToKpa = 6.89476;

  /// Field keys used for grow-space entity slots.
  static const String temperature = 'temperature';
  static const String humidity = 'humidity';
  static const String vpd = 'vpd';
  static const String soilMoisture = 'soil_moisture';

  double? temperatureF(HAEntityState? state) {
    final raw = state?.numericState;
    if (raw == null || !raw.isFinite) return null;
    return temperatureFFromRaw(raw, state?.unit);
  }

  double? temperatureFFromRaw(double raw, String? unit) {
    final normalized = (unit ?? '').trim().toLowerCase();
    final isCelsius = normalized == '°c' || normalized == 'c';
    return sanitizeTemperatureF(isCelsius ? celsiusToFahrenheit(raw) : raw);
  }

  double? humidityPct(HAEntityState? state) {
    final raw = state?.numericState;
    if (raw == null || !raw.isFinite) return null;
    return sanitizeHumidityPct(raw);
  }

  /// AC Infinity and some others report VPD in psi, or with no unit at all;
  /// both are treated as psi and converted.
  double? vpdKpa(HAEntityState? state) {
    final raw = state?.numericState;
    if (raw == null || !raw.isFinite) return null;
    return vpdKpaFromRaw(raw, state?.unit);
  }

  double? vpdKpaFromRaw(double raw, String? unit) {
    final normalized = (unit ?? '').trim().toLowerCase();
    if (normalized == 'kpa') return sanitizeVpdKpa(raw);
    if (normalized == 'hpa') return sanitizeVpdKpa(raw / 10);
    if (normalized == 'psi' ||
        normalized == 'lb/in²' ||
        normalized == 'lb/in2' ||
        normalized.isEmpty) {
      return sanitizeVpdKpa(raw * psiToKpa);
    }
    return sanitizeVpdKpa(raw);
  }

  double? soilMoisturePct(HAEntityState? state) {
    final raw = state?.numericState;
    if (raw == null || !raw.isFinite) return null;
    return sanitizeSoilMoisturePct(raw);
  }

  /// Canonical VPD from temperature and humidity, falling back to the
  /// entity's own value only when an input is missing.
  double? canonicalVpd({
    required double? tempF,
    required double? humidityPct,
    required double? upstreamVpdKpa,
  }) {
    return sanitizeVpdKpa(vpdKpaFromFahrenheit(tempF, humidityPct)) ??
        upstreamVpdKpa;
  }
}
