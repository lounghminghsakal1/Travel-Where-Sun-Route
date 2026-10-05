import 'dart:math' as math;

import '../entities/geo_point.dart';

/// Bearing, distance and interpolation helpers on a spherical earth.
class GeoUtils {
  const GeoUtils._();

  static const double earthRadiusKm = 6371.0088;

  static double toRad(double deg) => deg * math.pi / 180;
  static double toDeg(double rad) => rad * 180 / math.pi;

  /// Normalises any angle to the range [0, 360).
  static double normalizeDeg(double deg) => ((deg % 360) + 360) % 360;

  /// Great-circle distance in kilometres (haversine).
  static double distanceKm(GeoPoint a, GeoPoint b) {
    final dLat = toRad(b.lat - a.lat);
    final dLng = toRad(b.lng - a.lng);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(toRad(a.lat)) *
            math.cos(toRad(b.lat)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * earthRadiusKm * math.asin(math.min(1, math.sqrt(h)));
  }

  /// Initial bearing from [a] to [b], in degrees clockwise from north.
  static double bearing(GeoPoint a, GeoPoint b) {
    final lat1 = toRad(a.lat);
    final lat2 = toRad(b.lat);
    final dLng = toRad(b.lng - a.lng);
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return normalizeDeg(toDeg(math.atan2(y, x)));
  }

  /// Linear interpolation; accurate enough between closely spaced points.
  static GeoPoint lerp(GeoPoint a, GeoPoint b, double t) =>
      GeoPoint(a.lat + (b.lat - a.lat) * t, a.lng + (b.lng - a.lng) * t);

  /// Interpolates between two headings along the shortest arc.
  static double lerpAngle(double a, double b, double t) {
    final delta = ((b - a + 540) % 360) - 180;
    return normalizeDeg(a + delta * t);
  }

  /// Signed smallest difference `b - a` in degrees, in (-180, 180].
  static double angleDelta(double a, double b) => ((b - a + 540) % 360) - 180;
}
