import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Keys loaded from the bundled `.env` file.
class Env {
  const Env._();

  static String get googleMapsKey => _get('GOOGLE_MAPS_API_KEY');
  static String get openWeatherKey => _get('OPENWEATHER_API_KEY');

  static String _get(String name) =>
      dotenv.isInitialized ? (dotenv.maybeGet(name) ?? '').trim() : '';
}
