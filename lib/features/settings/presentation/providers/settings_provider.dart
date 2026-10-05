import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/storage/preferences.dart';
import '../../../seat_scoring/domain/entities/vehicle_layout.dart';
import '../../data/settings_local_data_source.dart';
import '../../domain/entities/app_settings.dart';

final settingsLocalDataSourceProvider = Provider<SettingsLocalDataSource>(
  (ref) => SettingsLocalDataSource(ref.watch(sharedPreferencesProvider)),
);

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsLocalDataSourceProvider).read();

  Future<void> _update(AppSettings next) async {
    state = next;
    await ref.read(settingsLocalDataSourceProvider).save(next);
  }

  Future<void> setGoogleKey(String key) =>
      _update(state.copyWith(googleKeyOverride: key.trim()));

  Future<void> setWeatherKey(String key) =>
      _update(state.copyWith(weatherKeyOverride: key.trim()));

  Future<void> setDriverPosition(DriverPosition p) =>
      _update(state.copyWith(driverPosition: p));
}

/// Effective Google key: Settings override, else `.env`.
final googleApiKeyProvider = Provider<String>((ref) {
  final custom = ref.watch(settingsProvider.select((s) => s.googleKeyOverride));
  return custom.isNotEmpty ? custom : Env.googleMapsKey;
});

/// Effective OpenWeather key: Settings override, else `.env`.
final weatherApiKeyProvider = Provider<String>((ref) {
  final custom = ref.watch(settingsProvider.select((s) => s.weatherKeyOverride));
  return custom.isNotEmpty ? custom : Env.openWeatherKey;
});
