class AppConstants {
  const AppConstants._();

  /// Name shown by the OS (launcher label, recent-apps title).
  static const appName = 'Travel Where';
  static const packageName = 'com.travel_app';

  /// OpenWeather free tier covers 5 days of 3-hour slots.
  static const forecastWindow = Duration(days: 5);

  /// Waypoint spacing for weather sampling.
  static const weatherSpacingKm = 20.0;
  static const maxWeatherWaypoints = 12;
  static const weatherCacheTtl = Duration(minutes: 60);

  /// At 1× playback, one real second covers this many journey seconds.
  static const playbackBaseRate = 120.0;
  static const playbackSpeeds = [1.0, 2.0, 5.0, 10.0];

  /// A seat counts as "in the sun" above this weather-adjusted intensity.
  static const sunExposureThreshold = 0.22;
}
