import 'dart:math' as math;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../sun_analysis/domain/entities/route_point.dart';
import '../entities/weather_data.dart';
import '../repositories/weather_repository.dart';

class WeatherAlongRoute {
  const WeatherAlongRoute({
    required this.waypoints,
    required this.points,
    required this.available,
    required this.beyondForecast,
    this.failure,
  });

  final List<WeatherWaypoint> waypoints;

  /// Route points with weather and nearest place name attached.
  final List<RoutePoint> points;

  /// False when no forecast could be fetched at all.
  final bool available;

  /// True when part of the trip is later than the forecast window.
  final bool beyondForecast;
  final Failure? failure;
}

/// Samples forecasts every ~20 km and attaches the forecast valid at each
/// route point's arrival time.
class GetWeatherAlongRoute {
  const GetWeatherAlongRoute(this._repository);
  final WeatherRepository _repository;

  Future<WeatherAlongRoute> call(List<RoutePoint> points) async {
    if (points.isEmpty) {
      return const WeatherAlongRoute(
        waypoints: [],
        points: [],
        available: false,
        beyondForecast: false,
      );
    }

    final indices = _waypointIndices(points);
    final results = await Future.wait(
      indices.map((i) => _repository.getForecast(points[i].location)),
    );

    Failure? firstFailure;
    var beyond = false;
    final waypoints = <WeatherWaypoint>[];
    for (var k = 0; k < indices.length; k++) {
      final p = points[indices[k]];
      final forecast = results[k].fold<WeatherForecast?>((f) {
        firstFailure ??= f;
        return null;
      }, (v) => v);
      final covered = forecast?.covers(p.timestamp) ?? false;
      if (forecast != null && !covered) beyond = true;
      waypoints.add(WeatherWaypoint(
        location: p.location,
        distanceKm: p.distanceFromStartKm,
        eta: p.timestamp,
        pointIndex: p.index,
        placeName: forecast?.placeName,
        forecast: forecast,
        weather: covered ? forecast!.at(p.timestamp) : null,
        beyondForecast: forecast != null && !covered,
      ));
    }

    final withForecast = waypoints.where((w) => w.forecast != null).toList();
    final named = waypoints.where((w) => (w.placeName ?? '').isNotEmpty).toList();

    final enriched = [
      for (final p in points)
        p.withWeather(
          _weatherFor(p, withForecast),
          _nearest(p, named)?.placeName,
        ),
    ];

    return WeatherAlongRoute(
      waypoints: waypoints,
      points: enriched,
      available: withForecast.isNotEmpty,
      beyondForecast: beyond,
      failure: withForecast.isEmpty ? firstFailure : null,
    );
  }

  WeatherData? _weatherFor(RoutePoint p, List<WeatherWaypoint> sources) {
    final wp = _nearest(p, sources);
    final forecast = wp?.forecast;
    if (forecast == null || !forecast.covers(p.timestamp)) return null;
    return forecast.at(p.timestamp);
  }

  WeatherWaypoint? _nearest(RoutePoint p, List<WeatherWaypoint> sources) {
    WeatherWaypoint? best;
    var bestD = double.infinity;
    for (final w in sources) {
      final d = (w.distanceKm - p.distanceFromStartKm).abs();
      if (d < bestD) {
        bestD = d;
        best = w;
      }
    }
    return best;
  }

  List<int> _waypointIndices(List<RoutePoint> points) {
    final totalKm = points.last.distanceFromStartKm;
    final count = math
        .max(2, (totalKm / AppConstants.weatherSpacingKm).ceil() + 1)
        .clamp(2, AppConstants.maxWeatherWaypoints);
    final indices = <int>{};
    var cursor = 0;
    for (var k = 0; k < count; k++) {
      final target = totalKm * k / (count - 1);
      while (cursor < points.length - 1 &&
          points[cursor + 1].distanceFromStartKm <= target) {
        cursor++;
      }
      indices.add(cursor);
    }
    indices.add(points.length - 1);
    return indices.toList()..sort();
  }
}
