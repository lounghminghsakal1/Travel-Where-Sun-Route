import '../../../../core/entities/geo_point.dart';
import '../../../../core/utils/polyline_decoder.dart';
import '../../domain/entities/route_info.dart';

/// Parses route responses from Google Routes API and OSRM.
class RouteModel {
  const RouteModel._();

  /// Google Routes API `computeRoutes` → [RouteInfo], or null if no route.
  static RouteInfo? fromGoogleRoutes(Map<String, dynamic> json) {
    final routes = json['routes'] as List?;
    if (routes == null || routes.isEmpty) return null;
    final r = routes.first as Map;
    final encoded = (r['polyline'] as Map?)?['encodedPolyline'] as String?;
    if (encoded == null) return null;
    final duration = (r['duration'] as String? ?? '0s').replaceAll('s', '');
    return RouteInfo(
      points: PolylineDecoder.decode(encoded),
      distanceMeters: (r['distanceMeters'] as num?)?.toDouble() ?? 0,
      durationSeconds: double.tryParse(duration) ?? 0,
      provider: 'Google Routes',
    );
  }

  /// OSRM `route` with GeoJSON geometry and per-segment duration annotations.
  static RouteInfo? fromOsrm(Map<String, dynamic> json) {
    if (json['code'] != 'Ok') return null;
    final routes = json['routes'] as List?;
    if (routes == null || routes.isEmpty) return null;
    final r = routes.first as Map;
    final coords = ((r['geometry'] as Map?)?['coordinates'] as List?) ?? const [];
    final points = [
      for (final c in coords)
        GeoPoint((c[1] as num).toDouble(), (c[0] as num).toDouble()),
    ];

    final segments = <double>[];
    for (final leg in (r['legs'] as List? ?? const [])) {
      final durations = ((leg as Map)['annotation'] as Map?)?['duration'] as List?;
      if (durations == null) {
        segments.clear();
        break;
      }
      segments.addAll(durations.map((d) => (d as num).toDouble()));
    }

    return RouteInfo(
      points: points,
      distanceMeters: (r['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (r['duration'] as num?)?.toDouble() ?? 0,
      segmentDurations: segments.length == points.length - 1 ? segments : null,
      provider: 'OpenStreetMap (OSRM)',
    );
  }
}
