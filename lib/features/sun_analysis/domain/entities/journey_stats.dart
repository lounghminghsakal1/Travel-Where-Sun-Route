import 'dart:math' as math;

import '../../../../core/utils/geo_utils.dart';
import 'route_point.dart';

enum SunEventType { sunrise, sunset }

class SunEvent {
  const SunEvent(this.type, this.time, this.progress);
  final SunEventType type;
  final DateTime time;

  /// 0–1 position along the journey timeline.
  final double progress;
}

/// Journey-wide sun and weather summary.
class JourneyStats {
  const JourneyStats({
    required this.totalMinutes,
    required this.daylightMinutes,
    required this.leftShare,
    required this.rightShare,
    required this.frontRearShare,
    required this.overheadShare,
    required this.avgCloudCover,
    required this.cloudReduction,
    required this.events,
  });

  final double totalMinutes;
  final double daylightMinutes;

  /// Intensity-weighted share of daylight sun coming from each direction.
  final double leftShare;
  final double rightShare;
  final double frontRearShare;
  final double overheadShare;

  /// Mean cloud cover (0–100) over daylight minutes.
  final double avgCloudCover;

  /// 0–1: how much clouds cut total sunlight on this trip.
  final double cloudReduction;
  final List<SunEvent> events;

  bool get isNight => daylightMinutes < 1;

  /// "left", "right", or null when roughly balanced.
  String? get dominantSide {
    if (isNight) return null;
    if (rightShare > leftShare * 1.25 && rightShare > 0.15) return 'right';
    if (leftShare > rightShare * 1.25 && leftShare > 0.15) return 'left';
    return null;
  }

  static JourneyStats fromPoints(List<RoutePoint> points) {
    double total = 0, daylight = 0, left = 0, right = 0, frontRear = 0, overhead = 0;
    double cloudSum = 0, raw = 0, adjusted = 0;
    final events = <SunEvent>[];
    final start = points.isEmpty ? null : points.first.timestamp;
    final end = points.isEmpty ? null : points.last.timestamp;
    final spanMs = (start != null && end != null)
        ? math.max(1, end.difference(start).inMilliseconds)
        : 1;

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      total += p.weightMinutes;
      if (i > 0) {
        final wasUp = points[i - 1].sun.isUp;
        if (wasUp != p.sun.isUp) {
          events.add(SunEvent(
            p.sun.isUp ? SunEventType.sunrise : SunEventType.sunset,
            p.timestamp,
            p.timestamp.difference(start!).inMilliseconds / spanMs,
          ));
        }
      }
      if (!p.sun.isUp) continue;
      daylight += p.weightMinutes;
      cloudSum += (p.weather?.cloudCover ?? 0) * p.weightMinutes;
      final strength = math.cos(GeoUtils.toRad(p.sun.altitude)) * p.weightMinutes;
      raw += strength;
      adjusted += strength * p.sunlightFactor;
      if (p.sun.altitude > 65) {
        overhead += strength;
        continue;
      }
      final lateral = math.sin(GeoUtils.toRad(p.sunRelativeAngle));
      final longi = math.cos(GeoUtils.toRad(p.sunRelativeAngle));
      if (lateral > 0) right += strength * lateral * lateral;
      if (lateral < 0) left += strength * lateral * lateral;
      frontRear += strength * longi * longi;
    }

    final dirTotal = left + right + frontRear + overhead;
    double share(double v) => dirTotal > 0 ? v / dirTotal : 0;
    return JourneyStats(
      totalMinutes: total,
      daylightMinutes: daylight,
      leftShare: share(left),
      rightShare: share(right),
      frontRearShare: share(frontRear),
      overheadShare: share(overhead),
      avgCloudCover: daylight > 0 ? cloudSum / daylight : 0,
      cloudReduction: raw > 0 ? 1 - adjusted / raw : 0,
      events: events,
    );
  }
}
