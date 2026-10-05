import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/entities/geo_point.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/weather_data.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/weather_remote_data_source.dart';
import '../models/weather_forecast_model.dart';

/// Fetches forecasts with an in-memory + SharedPreferences cache so repeated
/// searches stay within OpenWeather's rate limits and survive brief outages.
class WeatherRepositoryImpl implements WeatherRepository {
  WeatherRepositoryImpl(this._remote, this._prefs);

  final WeatherRemoteDataSource _remote;
  final SharedPreferences _prefs;
  final _memory = <String, Future<Map<String, dynamic>>>{};

  static const _prefix = 'wx_cache:';

  @override
  Future<Result<WeatherForecast>> getForecast(GeoPoint location) async {
    final key = '$_prefix${location.lat.toStringAsFixed(2)},${location.lng.toStringAsFixed(2)}';
    final cached = _readCache(key, fresh: true);
    if (cached != null) return Ok(WeatherForecastModel.fromJson(cached));

    try {
      final json = await _memory.putIfAbsent(
        key,
        () => _remote.getForecast(lat: location.lat, lon: location.lng),
      );
      _writeCache(key, json);
      return Ok(WeatherForecastModel.fromJson(json));
    } catch (e) {
      _memory.remove(key);
      // Stale data beats no data when offline or rate-limited.
      final stale = _readCache(key, fresh: false);
      if (stale != null) return Ok(WeatherForecastModel.fromJson(stale));
      return Err(mapErrorToFailure(e, service: 'OpenWeather'));
    }
  }

  Map<String, dynamic>? _readCache(String key, {required bool fresh}) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.fromMillisecondsSinceEpoch(decoded['savedAt'] as int);
      if (fresh && DateTime.now().difference(savedAt) > AppConstants.weatherCacheTtl) {
        return null;
      }
      return decoded['data'] as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  void _writeCache(String key, Map<String, dynamic> json) {
    _prefs.setString(
      key,
      jsonEncode({'savedAt': DateTime.now().millisecondsSinceEpoch, 'data': json}),
    );
  }

  Future<void> clearCache() async {
    _memory.clear();
    for (final k in _prefs.getKeys().where((k) => k.startsWith(_prefix)).toList()) {
      await _prefs.remove(k);
    }
  }
}
