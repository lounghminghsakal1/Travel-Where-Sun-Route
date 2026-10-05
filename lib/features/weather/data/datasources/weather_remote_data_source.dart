import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';

class WeatherRemoteDataSource {
  WeatherRemoteDataSource(this._dio, this._apiKey);

  final Dio _dio;
  final String Function() _apiKey;

  /// Raw forecast JSON for a coordinate.
  Future<Map<String, dynamic>> getForecast({
    required double lat,
    required double lon,
  }) async {
    final key = _apiKey();
    if (key.isEmpty) {
      throw const AppException(
        ApiKeyFailure('OpenWeather', 'No OpenWeather API key set. Add one in Settings.'),
      );
    }
    final response = await _dio.get<Map<String, dynamic>>(
      ApiConstants.owmForecast,
      queryParameters: {
        'lat': lat.toStringAsFixed(4),
        'lon': lon.toStringAsFixed(4),
        'units': 'metric',
        'appid': key,
      },
    );
    return response.data ?? const {};
  }
}
