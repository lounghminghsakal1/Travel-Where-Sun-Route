import '../../../seat_scoring/domain/entities/vehicle_layout.dart';

class AppSettings {
  const AppSettings({
    this.googleKeyOverride = '',
    this.weatherKeyOverride = '',
    required this.driverPosition,
  });

  /// Keys typed in Settings; empty means "use the bundled .env key".
  final String googleKeyOverride;
  final String weatherKeyOverride;
  final DriverPosition driverPosition;

  AppSettings copyWith({
    String? googleKeyOverride,
    String? weatherKeyOverride,
    DriverPosition? driverPosition,
  }) =>
      AppSettings(
        googleKeyOverride: googleKeyOverride ?? this.googleKeyOverride,
        weatherKeyOverride: weatherKeyOverride ?? this.weatherKeyOverride,
        driverPosition: driverPosition ?? this.driverPosition,
      );
}
