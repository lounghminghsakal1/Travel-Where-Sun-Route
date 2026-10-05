import '../../../../core/entities/geo_point.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../route_input/domain/entities/route_info.dart';
import '../../../route_input/domain/entities/trip_request.dart';
import '../../../seat_scoring/domain/entities/seat_score.dart';
import '../../../seat_scoring/domain/entities/seat_zone.dart';
import '../../../seat_scoring/domain/entities/vehicle_layout.dart';
import '../../../sun_analysis/domain/entities/journey_stats.dart';
import '../../../sun_analysis/domain/entities/route_point.dart';
import '../../../sun_analysis/domain/entities/sun_position.dart';
import '../../../weather/domain/entities/weather_data.dart';

/// Everything the results UI needs about one analysed trip.
class TripAnalysis {
  TripAnalysis({
    required this.request,
    required this.route,
    required this.points,
    required this.layout,
    required this.stats,
    required this.scores,
    required this.exposure,
    required this.preferences,
    required this.avoid,
    required this.waypoints,
    required this.weatherAvailable,
    required this.beyondForecast,
    this.weatherFailure,
  }) : scoreById = {for (final s in scores) s.seatId: s};

  final TripRequest request;
  final RouteInfo route;
  final List<RoutePoint> points;
  final VehicleLayout layout;
  final JourneyStats stats;

  /// Ranked best → worst.
  final List<SeatScore> scores;
  final Map<String, SeatScore> scoreById;
  final Map<String, List<double>> exposure;
  final List<SeatZone> preferences;
  final SeatZone? avoid;
  final List<WeatherWaypoint> waypoints;
  final bool weatherAvailable;
  final bool beyondForecast;
  final Failure? weatherFailure;

  DateTime get departure => points.first.timestamp;
  DateTime get arrival => points.last.timestamp;
  Duration get duration => arrival.difference(departure);
  double get distanceKm => route.distanceMeters / 1000;

  double progressOf(DateTime t) {
    final total = duration.inMilliseconds;
    if (total <= 0) return 0;
    return (t.difference(departure).inMilliseconds / total).clamp(0.0, 1.0);
  }

  double progressOfIndex(int i) => progressOf(points[i].timestamp);

  /// Interpolated state of the journey at [progress] (0–1).
  JourneyFrame frameAt(double progress) {
    final p = progress.clamp(0.0, 1.0);
    final target = departure.add(Duration(milliseconds: (duration.inMilliseconds * p).round()));

    var lo = 0;
    var hi = points.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (points[mid].timestamp.isAfter(target)) {
        hi = mid;
      } else {
        lo = mid;
      }
    }
    final a = points[lo];
    final b = points[hi];
    final span = b.timestamp.difference(a.timestamp).inMilliseconds;
    final f = span <= 0 ? 0.0 : (target.difference(a.timestamp).inMilliseconds / span).clamp(0.0, 1.0);
    double mix(double x, double y) => x + (y - x) * f;

    final bearing = GeoUtils.lerpAngle(a.bearing, b.bearing, f);
    final azimuth = GeoUtils.lerpAngle(a.sun.azimuth, b.sun.azimuth, f);
    final altitude = mix(a.sun.altitude, b.sun.altitude);
    final relative = GeoUtils.normalizeDeg(azimuth - bearing);
    final near = f < 0.5 ? a : b;

    return JourneyFrame(
      progress: p,
      time: target,
      location: GeoUtils.lerp(a.location, b.location, f),
      bearing: bearing,
      sun: SunPosition(azimuth: azimuth, altitude: altitude),
      sunRelativeAngle: relative,
      sunSide: SunSide.fromRelative(relative, altitude),
      weather: near.weather,
      distanceKm: mix(a.distanceFromStartKm, b.distanceFromStartKm),
      speedKmh: mix(a.speedKmh, b.speedKmh),
      placeName: near.placeName,
      pointIndex: near.index,
      seatExposure: {
        for (final e in exposure.entries) e.key: mix(e.value[lo], e.value[hi]),
      },
    );
  }
}

class JourneyFrame {
  const JourneyFrame({
    required this.progress,
    required this.time,
    required this.location,
    required this.bearing,
    required this.sun,
    required this.sunRelativeAngle,
    required this.sunSide,
    required this.weather,
    required this.distanceKm,
    required this.speedKmh,
    required this.placeName,
    required this.pointIndex,
    required this.seatExposure,
  });

  final double progress;
  final DateTime time;
  final GeoPoint location;
  final double bearing;
  final SunPosition sun;
  final double sunRelativeAngle;
  final SunSide sunSide;
  final WeatherData? weather;
  final double distanceKm;
  final double speedKmh;
  final String? placeName;
  final int pointIndex;
  final Map<String, double> seatExposure;

  /// "4 o'clock" style direction of the sun relative to the vehicle.
  String get clockPosition {
    final hour = (sunRelativeAngle / 30).round() % 12;
    return "${hour == 0 ? 12 : hour} o'clock";
  }
}
