import 'dart:math' as math;

import 'geo_utils.dart';

/// Sun azimuth/altitude for a moment and place.
class SunAngles {
  const SunAngles({required this.azimuth, required this.altitude});

  /// Degrees clockwise from true north, 0–360.
  final double azimuth;

  /// Degrees above the horizon (negative when the sun has set).
  final double altitude;
}

/// Solar position using the NOAA spreadsheet algorithm (accurate to roughly
/// 0.01° for dates between 1901 and 2099). Pure Dart, no network calls.
class SunUtils {
  const SunUtils._();

  static SunAngles position(DateTime time, double lat, double lng) {
    final utc = time.toUtc();
    final julianDay = utc.millisecondsSinceEpoch / 86400000.0 + 2440587.5;
    final t = (julianDay - 2451545.0) / 36525.0;

    final meanLong = (280.46646 + t * (36000.76983 + t * 0.0003032)) % 360;
    final meanAnomaly = 357.52911 + t * (35999.05029 - 0.0001537 * t);
    final eccentricity = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
    final m = GeoUtils.toRad(meanAnomaly);

    final center = math.sin(m) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
        math.sin(2 * m) * (0.019993 - 0.000101 * t) +
        math.sin(3 * m) * 0.000289;
    final trueLong = meanLong + center;
    final omega = GeoUtils.toRad(125.04 - 1934.136 * t);
    final apparentLong = trueLong - 0.00569 - 0.00478 * math.sin(omega);

    final seconds = 21.448 - t * (46.815 + t * (0.00059 - t * 0.001813));
    final meanObliquity = 23 + (26 + seconds / 60) / 60;
    final obliquity =
        GeoUtils.toRad(meanObliquity + 0.00256 * math.cos(omega));

    final declination = math.asin(
      math.sin(obliquity) * math.sin(GeoUtils.toRad(apparentLong)),
    );

    final y = math.pow(math.tan(obliquity / 2), 2).toDouble();
    final l0 = GeoUtils.toRad(meanLong);
    final equationOfTime = 4 *
        GeoUtils.toDeg(
          y * math.sin(2 * l0) -
              2 * eccentricity * math.sin(m) +
              4 * eccentricity * y * math.sin(m) * math.cos(2 * l0) -
              0.5 * y * y * math.sin(4 * l0) -
              1.25 * eccentricity * eccentricity * math.sin(2 * m),
        );

    final utcMinutes = utc.hour * 60 +
        utc.minute +
        utc.second / 60 +
        utc.millisecond / 60000;
    final trueSolarTime = (utcMinutes + equationOfTime + 4 * lng) % 1440;
    final hourAngle = GeoUtils.toRad(trueSolarTime / 4 - 180);

    final latRad = GeoUtils.toRad(lat);
    final cosZenith = (math.sin(latRad) * math.sin(declination) +
            math.cos(latRad) * math.cos(declination) * math.cos(hourAngle))
        .clamp(-1.0, 1.0);
    final zenith = math.acos(cosZenith);
    var altitude = 90 - GeoUtils.toDeg(zenith);
    altitude += _refraction(altitude);

    final azimuth = GeoUtils.normalizeDeg(
      GeoUtils.toDeg(
            math.atan2(
              math.sin(hourAngle),
              math.cos(hourAngle) * math.sin(latRad) -
                  math.tan(declination) * math.cos(latRad),
            ),
          ) +
          180,
    );

    return SunAngles(azimuth: azimuth, altitude: altitude);
  }

  /// Atmospheric refraction correction in degrees (NOAA approximation).
  static double _refraction(double elevation) {
    if (elevation > 85) return 0;
    final te = math.tan(GeoUtils.toRad(elevation));
    double arcSeconds;
    if (elevation > 5) {
      arcSeconds = 58.1 / te - 0.07 / math.pow(te, 3) + 0.000086 / math.pow(te, 5);
    } else if (elevation > -0.575) {
      arcSeconds = 1735 +
          elevation *
              (-518.2 + elevation * (103.4 + elevation * (-12.79 + elevation * 0.711)));
    } else {
      arcSeconds = -20.774 / te;
    }
    return arcSeconds / 3600;
  }
}
