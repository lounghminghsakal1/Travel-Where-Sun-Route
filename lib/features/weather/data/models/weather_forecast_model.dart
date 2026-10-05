import '../../domain/entities/weather_data.dart';

/// Parses OpenWeatherMap's 5 day / 3 hour forecast response.
class WeatherForecastModel {
  const WeatherForecastModel._();

  static WeatherForecast fromJson(Map<String, dynamic> json) {
    final list = (json['list'] as List?) ?? const [];
    final city = (json['city'] as Map?) ?? const {};
    final slots = <ForecastSlot>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      final dt = (raw['dt'] as num?)?.toInt();
      if (dt == null) continue;
      slots.add(ForecastSlot(
        DateTime.fromMillisecondsSinceEpoch(dt * 1000, isUtc: true),
        _weather(raw),
      ));
    }
    slots.sort((a, b) => a.time.compareTo(b.time));
    return WeatherForecast(
      slots: slots,
      placeName: (city['name'] as String?) ?? '',
      timezoneOffsetSeconds: (city['timezone'] as num?)?.toInt() ?? 0,
    );
  }

  static WeatherData _weather(Map raw) {
    final main = (raw['main'] as Map?) ?? const {};
    final weatherList = (raw['weather'] as List?) ?? const [];
    final w = weatherList.isNotEmpty && weatherList.first is Map
        ? weatherList.first as Map
        : const {};
    final clouds = ((raw['clouds'] as Map?)?['all'] as num?)?.toInt() ?? 0;
    final id = (w['id'] as num?)?.toInt() ?? 800;
    return WeatherData(
      condition: conditionFor(id, clouds),
      cloudCover: clouds,
      temperature: (main['temp'] as num?)?.toDouble() ?? 0,
      humidity: (main['humidity'] as num?)?.toInt() ?? 0,
      windSpeed: ((raw['wind'] as Map?)?['speed'] as num?)?.toDouble() ?? 0,
      icon: (w['icon'] as String?) ?? '01d',
      description: (w['description'] as String?) ?? '',
      precipitationChance: (raw['pop'] as num?)?.toDouble() ?? 0,
    );
  }

  /// OpenWeather condition codes → app conditions.
  static WeatherCondition conditionFor(int id, int clouds) {
    if (id >= 200 && id < 300) return WeatherCondition.storm;
    if (id >= 300 && id < 600) return WeatherCondition.rain;
    if (id >= 600 && id < 700) return WeatherCondition.snow;
    if (id >= 700 && id < 800) return WeatherCondition.fog;
    if (clouds < 20) return WeatherCondition.clear;
    if (clouds < 60) return WeatherCondition.partlyCloudy;
    if (clouds < 90) return WeatherCondition.cloudy;
    return WeatherCondition.overcast;
  }
}
