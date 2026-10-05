import '../../../../core/entities/geo_point.dart';
import '../../../weather/domain/entities/weather_data.dart';
import 'sun_position.dart';

/// One sample along the journey (roughly every minute of travel).
class RoutePoint {
  const RoutePoint({
    required this.index,
    required this.location,
    required this.timestamp,
    required this.bearing,
    required this.speedKmh,
    required this.distanceFromStartKm,
    required this.sun,
    required this.sunRelativeAngle,
    required this.sunSide,
    required this.weightMinutes,
    this.weather,
    this.placeName,
  });

  final int index;
  final GeoPoint location;

  /// UTC.
  final DateTime timestamp;

  /// Vehicle heading, degrees clockwise from north.
  final double bearing;
  final double speedKmh;
  final double distanceFromStartKm;
  final SunPosition sun;

  /// Sun azimuth relative to heading: 0 ahead, 90 right, 270 left.
  final double sunRelativeAngle;
  final SunSide sunSide;

  /// Journey minutes this sample stands for (used when integrating exposure).
  final double weightMinutes;
  final WeatherData? weather;

  /// Nearest named place, when known.
  final String? placeName;

  double get sunlightFactor => weather?.sunlightFactor ?? 1.0;

  RoutePoint withWeather(WeatherData? weather, String? placeName) => RoutePoint(
        index: index,
        location: location,
        timestamp: timestamp,
        bearing: bearing,
        speedKmh: speedKmh,
        distanceFromStartKm: distanceFromStartKm,
        sun: sun,
        sunRelativeAngle: sunRelativeAngle,
        sunSide: sunSide,
        weightMinutes: weightMinutes,
        weather: weather,
        placeName: placeName,
      );
}
