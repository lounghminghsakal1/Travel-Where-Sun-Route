import 'dart:math' as math;

import '../../../../core/constants/app_constants.dart';
import '../../../sun_analysis/domain/entities/route_point.dart';
import '../entities/seat_score.dart';
import '../entities/vehicle_layout.dart';
import 'exposure_model.dart';

class SeatScoringResult {
  const SeatScoringResult({required this.scores, required this.exposure});

  /// Ranked best → worst (passenger seats only).
  final List<SeatScore> scores;

  /// Weather-adjusted intensity per seat per route point (includes driver).
  final Map<String, List<double>> exposure;
}

/// Integrates sun exposure for every seat over the journey and combines it
/// with ventilation and comfort into a 0–100 score (plan steps 6–8).
class ComputeSeatScores {
  const ComputeSeatScores();

  /// Average intensity that maps to a sun-protection score of 0.
  static const _saturation = 0.6;

  SeatScoringResult call(VehicleLayout layout, List<RoutePoint> points) {
    final journeyMinutes = points.fold<double>(0, (a, p) => a + p.weightMinutes);
    final exposure = <String, List<double>>{};
    final scores = <SeatScore>[];

    for (final seat in layout.seatMap) {
      final series = List<double>.filled(points.length, 0);
      var raw = 0.0, adjusted = 0.0, peak = 0.0, sunMinutes = 0.0, daylight = 0.0;

      for (var i = 0; i < points.length; i++) {
        final p = points[i];
        final intensity = ExposureModel.seatIntensity(
          seat,
          layout,
          p.sunRelativeAngle,
          p.sun.altitude,
        );
        final a = intensity * p.sunlightFactor;
        series[i] = a;
        raw += intensity * p.weightMinutes;
        adjusted += a * p.weightMinutes;
        peak = math.max(peak, a);
        if (a >= AppConstants.sunExposureThreshold) sunMinutes += p.weightMinutes;
        if (p.sun.isUp) daylight += p.weightMinutes;
      }
      exposure[seat.id] = series;
      if (seat.isDriver) continue;

      final normalized = journeyMinutes > 0
          ? (adjusted / (journeyMinutes * _saturation)).clamp(0.0, 1.0)
          : 0.0;
      final sunProtection = 100 * (1 - normalized);
      final ventilation = ExposureModel.ventilation(seat, layout);
      final comfort = ExposureModel.comfort(seat, layout);
      final overall =
          sunProtection * 0.65 + ventilation * 100 * 0.20 + comfort * 10 * 0.15;

      scores.add(SeatScore(
        seatId: seat.id,
        totalSunExposureMinutes: sunMinutes,
        peakExposureIntensity: peak,
        avgExposureIntensity: daylight > 0 ? adjusted / daylight : 0,
        rawExposure: raw,
        weatherAdjustedExposure: adjusted,
        sunProtectionScore: sunProtection,
        ventilationScore: ventilation,
        comfortScore: comfort,
        overallScore: overall,
      ));
    }

    scores.sort((a, b) {
      final byScore = b.overallScore.compareTo(a.overallScore);
      if (byScore != 0) return byScore;
      return b.sunProtectionScore.compareTo(a.sunProtectionScore);
    });
    final ranked = [
      for (var i = 0; i < scores.length; i++) scores[i].copyWith(rank: i + 1),
    ];
    return SeatScoringResult(scores: ranked, exposure: exposure);
  }
}
