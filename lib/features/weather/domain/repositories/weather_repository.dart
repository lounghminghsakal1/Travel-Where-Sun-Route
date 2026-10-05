import '../../../../core/entities/geo_point.dart';
import '../../../../core/error/result.dart';
import '../entities/weather_data.dart';

abstract interface class WeatherRepository {
  Future<Result<WeatherForecast>> getForecast(GeoPoint location);
}
