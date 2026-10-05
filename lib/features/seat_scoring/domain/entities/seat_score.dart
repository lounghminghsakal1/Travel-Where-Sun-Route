class SeatScore {
  const SeatScore({
    required this.seatId,
    required this.totalSunExposureMinutes,
    required this.peakExposureIntensity,
    required this.avgExposureIntensity,
    required this.rawExposure,
    required this.weatherAdjustedExposure,
    required this.sunProtectionScore,
    required this.ventilationScore,
    required this.comfortScore,
    required this.overallScore,
    this.rank = 0,
    this.recommendation = '',
    this.reason = '',
  });

  final String seatId;

  /// Minutes the seat sits in noticeable direct sun (weather-adjusted).
  final double totalSunExposureMinutes;

  /// 0–1 peak weather-adjusted intensity.
  final double peakExposureIntensity;

  /// 0–1 mean weather-adjusted intensity over daylight minutes.
  final double avgExposureIntensity;

  /// Intensity-minutes ignoring weather.
  final double rawExposure;

  /// Intensity-minutes after cloud cover.
  final double weatherAdjustedExposure;

  /// 0–100.
  final double sunProtectionScore;

  /// 0–1.
  final double ventilationScore;

  /// 0–10 bonus points (view, front, near exit).
  final double comfortScore;

  /// 0–100.
  final double overallScore;
  final int rank;
  final String recommendation;
  final String reason;

  SeatScore copyWith({int? rank, String? recommendation, String? reason}) =>
      SeatScore(
        seatId: seatId,
        totalSunExposureMinutes: totalSunExposureMinutes,
        peakExposureIntensity: peakExposureIntensity,
        avgExposureIntensity: avgExposureIntensity,
        rawExposure: rawExposure,
        weatherAdjustedExposure: weatherAdjustedExposure,
        sunProtectionScore: sunProtectionScore,
        ventilationScore: ventilationScore,
        comfortScore: comfortScore,
        overallScore: overallScore,
        rank: rank ?? this.rank,
        recommendation: recommendation ?? this.recommendation,
        reason: reason ?? this.reason,
      );
}
