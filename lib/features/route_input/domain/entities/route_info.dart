import '../../../../core/entities/geo_point.dart';

class RouteInfo {
  const RouteInfo({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.provider,
    this.segmentDurations,
  });

  /// Full-resolution route geometry.
  final List<GeoPoint> points;

  /// Optional travel time (s) for each segment `points[i] → points[i+1]`.
  /// Lets the sampler follow real speed changes (city vs highway).
  final List<double>? segmentDurations;
  final double distanceMeters;
  final double durationSeconds;

  /// Which routing backend produced this route.
  final String provider;
}
