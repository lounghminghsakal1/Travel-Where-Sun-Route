import 'dart:math' as math;

import '../../../../core/entities/geo_point.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../route_input/domain/entities/route_info.dart';
import '../entities/route_point.dart';
import '../entities/sun_position.dart';
import '../repositories/sun_repository.dart';

/// Samples the route in time (≈ every minute) and computes the vehicle's
/// heading and the sun's position relative to it at each sample.
class ComputeSunPositions {
  const ComputeSunPositions(this._sun);
  final SunRepository _sun;

  List<RoutePoint> call({
    required RouteInfo route,
    required DateTime departure,
    double durationFactor = 1.0,
  }) {
    final geo = route.points;
    if (geo.length < 2) return const [];
    final track = _Track.build(route, durationFactor);
    final totalSeconds = track.totalSeconds;
    final totalMinutes = totalSeconds / 60;

    // Interval: 30 s for short trips, 1 min normally, 2–3 min for long ones,
    // capped at ~900 samples.
    var intervalMin = totalMinutes < 10
        ? 0.5
        : totalMinutes > 12 * 60
            ? 3.0
            : 1.0;
    if (totalMinutes / intervalMin > 900) intervalMin = totalMinutes / 900;
    final interval = intervalMin * 60;

    final times = <double>[];
    for (var t = 0.0; t < totalSeconds; t += interval) {
      times.add(t);
    }
    times.add(totalSeconds);

    final departureUtc = departure.toUtc();
    final points = <RoutePoint>[];
    for (var i = 0; i < times.length; i++) {
      final t = times[i];
      final distKm = track.distanceAtTime(t);
      final location = track.positionAtDistance(distKm);

      // Heading from a ±200 m window smooths jitter on dense polylines.
      final behind = track.positionAtDistance(math.max(0, distKm - 0.2));
      final ahead = track.positionAtDistance(math.min(track.totalKm, distKm + 0.2));
      final bearing = GeoUtils.bearing(behind, ahead);

      final dBefore = track.distanceAtTime(math.max(0, t - 30));
      final dAfter = track.distanceAtTime(math.min(totalSeconds, t + 30));
      final span = math.min(totalSeconds, t + 30) - math.max(0, t - 30);
      final speed = span > 0 ? (dAfter - dBefore) / span * 3600 : 0.0;

      final timestamp = departureUtc.add(Duration(milliseconds: (t * 1000).round()));
      final sun = _sun.positionAt(timestamp, location);
      final relative = GeoUtils.normalizeDeg(sun.azimuth - bearing);

      final prev = i == 0 ? t : times[i - 1];
      final next = i == times.length - 1 ? t : times[i + 1];
      final weight = (next - prev) / 2 / 60;

      points.add(RoutePoint(
        index: i,
        location: location,
        timestamp: timestamp,
        bearing: bearing,
        speedKmh: speed,
        distanceFromStartKm: distKm,
        sun: sun,
        sunRelativeAngle: relative,
        sunSide: SunSide.fromRelative(relative, sun.altitude),
        weightMinutes: weight,
      ));
    }
    return points;
  }
}

/// Cumulative distance/time along a polyline with lookup by either.
class _Track {
  _Track(this.points, this.cumKm, this.cumSec);

  final List<GeoPoint> points;
  final List<double> cumKm;
  final List<double> cumSec;

  double get totalKm => cumKm.last;
  double get totalSeconds => cumSec.last;

  static _Track build(RouteInfo route, double factor) {
    final pts = route.points;
    final cumKm = List<double>.filled(pts.length, 0);
    for (var i = 1; i < pts.length; i++) {
      cumKm[i] = cumKm[i - 1] + GeoUtils.distanceKm(pts[i - 1], pts[i]);
    }
    final totalKm = cumKm.last;
    final totalSec = math.max(60.0, route.durationSeconds * factor);

    final segs = route.segmentDurations;
    final cumSec = List<double>.filled(pts.length, 0);
    if (segs != null && segs.length == pts.length - 1) {
      final rawSum = segs.fold<double>(0, (a, b) => a + b);
      final scale = rawSum > 0 ? totalSec / rawSum : 0.0;
      for (var i = 1; i < pts.length; i++) {
        cumSec[i] = cumSec[i - 1] + segs[i - 1] * scale;
      }
    }
    if (cumSec.last <= 0) {
      for (var i = 1; i < pts.length; i++) {
        cumSec[i] = totalKm > 0 ? cumKm[i] / totalKm * totalSec : totalSec * i / (pts.length - 1);
      }
    }
    return _Track(pts, cumKm, cumSec);
  }

  double distanceAtTime(double t) {
    final i = _search(cumSec, t);
    final segT = cumSec[i + 1] - cumSec[i];
    final f = segT <= 0 ? 0.0 : ((t - cumSec[i]) / segT).clamp(0.0, 1.0);
    return cumKm[i] + (cumKm[i + 1] - cumKm[i]) * f;
  }

  GeoPoint positionAtDistance(double d) {
    final i = _search(cumKm, d);
    final segD = cumKm[i + 1] - cumKm[i];
    final f = segD <= 0 ? 0.0 : ((d - cumKm[i]) / segD).clamp(0.0, 1.0);
    return GeoUtils.lerp(points[i], points[i + 1], f);
  }

  /// Index i such that values[i] <= x < values[i+1] (clamped).
  static int _search(List<double> values, double x) {
    var lo = 0;
    var hi = values.length - 2;
    if (x <= values.first) return 0;
    if (x >= values.last) return hi;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (values[mid] <= x) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }
}
