import '../../../../core/entities/geo_point.dart';

enum WeatherCondition {
  clear('Clear'),
  partlyCloudy('Partly cloudy'),
  cloudy('Cloudy'),
  overcast('Overcast'),
  rain('Rain'),
  storm('Thunderstorm'),
  fog('Fog'),
  snow('Snow');

  const WeatherCondition(this.label);
  final String label;

  bool get isWet => this == rain || this == storm || this == snow;
}

class WeatherData {
  const WeatherData({
    required this.condition,
    required this.cloudCover,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.icon,
    required this.description,
    this.precipitationChance = 0,
  });

  final WeatherCondition condition;

  /// 0–100 %.
  final int cloudCover;

  /// °C.
  final double temperature;
  final int humidity;

  /// m/s.
  final double windSpeed;

  /// OpenWeather icon code, e.g. "02d".
  final String icon;
  final String description;

  /// 0–1.
  final double precipitationChance;

  /// Share of direct sunlight that gets through (1 = clear sky).
  double get sunlightFactor {
    var f = 1 - (cloudCover / 100) * 0.85;
    if (condition.isWet) f = f < 0.12 ? f : 0.12;
    if (condition == WeatherCondition.fog) f *= 0.35;
    return f.clamp(0.0, 1.0);
  }

  /// Blends numeric fields; categorical fields come from the closer slot.
  static WeatherData lerp(WeatherData a, WeatherData b, double t) {
    final near = t < 0.5 ? a : b;
    double mix(num x, num y) => x + (y - x) * t;
    return WeatherData(
      condition: near.condition,
      cloudCover: mix(a.cloudCover, b.cloudCover).round(),
      temperature: mix(a.temperature, b.temperature),
      humidity: mix(a.humidity, b.humidity).round(),
      windSpeed: mix(a.windSpeed, b.windSpeed),
      icon: near.icon,
      description: near.description,
      precipitationChance: mix(a.precipitationChance, b.precipitationChance),
    );
  }
}

class ForecastSlot {
  const ForecastSlot(this.time, this.weather);
  final DateTime time;
  final WeatherData weather;
}

class WeatherForecast {
  const WeatherForecast({
    required this.slots,
    required this.placeName,
    this.timezoneOffsetSeconds = 0,
  });

  /// Sorted ascending by time (UTC).
  final List<ForecastSlot> slots;
  final String placeName;
  final int timezoneOffsetSeconds;

  bool covers(DateTime t) =>
      slots.isNotEmpty &&
      !t.isAfter(slots.last.time.add(const Duration(hours: 3)));

  /// Interpolated forecast at [t]; clamps to the first/last slot.
  WeatherData? at(DateTime t) {
    if (slots.isEmpty) return null;
    if (!t.isAfter(slots.first.time)) return slots.first.weather;
    if (!t.isBefore(slots.last.time)) return slots.last.weather;
    for (var i = 0; i < slots.length - 1; i++) {
      final a = slots[i];
      final b = slots[i + 1];
      if (!t.isBefore(a.time) && t.isBefore(b.time)) {
        final span = b.time.difference(a.time).inSeconds;
        final into = t.difference(a.time).inSeconds;
        return WeatherData.lerp(a.weather, b.weather, span == 0 ? 0 : into / span);
      }
    }
    return slots.last.weather;
  }
}

/// A point along the route where weather was sampled.
class WeatherWaypoint {
  const WeatherWaypoint({
    required this.location,
    required this.distanceKm,
    required this.eta,
    required this.pointIndex,
    this.placeName,
    this.forecast,
    this.weather,
    this.beyondForecast = false,
  });

  final GeoPoint location;
  final double distanceKm;
  final DateTime eta;

  /// Index of the route sample this waypoint sits on.
  final int pointIndex;
  final String? placeName;
  final WeatherForecast? forecast;

  /// Forecast at [eta].
  final WeatherData? weather;
  final bool beyondForecast;
}
