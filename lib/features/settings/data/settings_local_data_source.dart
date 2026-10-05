import 'dart:ui' show PlatformDispatcher;

import 'package:shared_preferences/shared_preferences.dart';

import '../../seat_scoring/domain/entities/vehicle_layout.dart';
import '../domain/entities/app_settings.dart';

class SettingsLocalDataSource {
  SettingsLocalDataSource(this._prefs);
  final SharedPreferences _prefs;

  static const _googleKey = 'settings.google_key';
  static const _weatherKey = 'settings.weather_key';
  static const _driverKey = 'settings.driver_position';

  /// Countries that drive on the left, so the driver sits on the right.
  static const _leftHandTraffic = {
    'IN', 'GB', 'IE', 'AU', 'NZ', 'JP', 'ZA', 'SG', 'MY', 'TH', 'ID', 'PK',
    'BD', 'LK', 'NP', 'KE', 'UG', 'TZ', 'HK', 'MT', 'CY', 'JM', 'BT', 'MU',
  };

  AppSettings read() {
    final stored = _prefs.getString(_driverKey);
    return AppSettings(
      googleKeyOverride: _prefs.getString(_googleKey) ?? '',
      weatherKeyOverride: _prefs.getString(_weatherKey) ?? '',
      driverPosition: stored != null
          ? DriverPosition.values.byName(stored)
          : _defaultDriverPosition(),
    );
  }

  Future<void> save(AppSettings s) async {
    await _prefs.setString(_googleKey, s.googleKeyOverride);
    await _prefs.setString(_weatherKey, s.weatherKeyOverride);
    await _prefs.setString(_driverKey, s.driverPosition.name);
  }

  DriverPosition _defaultDriverPosition() {
    final country = PlatformDispatcher.instance.locale.countryCode?.toUpperCase();
    return _leftHandTraffic.contains(country) ? DriverPosition.right : DriverPosition.left;
  }
}
