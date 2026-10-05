import 'dart:math' as math;

import '../../../../core/utils/geo_utils.dart';
import '../entities/seat.dart';
import '../entities/vehicle_layout.dart';

/// Physical model of how much direct sun reaches a seat.
class ExposureModel {
  const ExposureModel._();

  /// Light reaching seats in daylight even on the shaded side.
  static const ambient = 0.05;

  /// 0–1 strength of sunlight entering through side glass at [altitude].
  ///
  /// Combines clear-sky direct irradiance (Kasten–Young air mass), the
  /// cos(altitude) projection onto vertical windows, a fade near the horizon
  /// where buildings and trees block the sun, and the roof blocking most light
  /// once the sun is above ~65°.
  static double altitudeFactor(double altitude) {
    if (altitude <= 0) return 0;
    final zenith = 90 - altitude;
    final airMass = 1 /
        (math.cos(GeoUtils.toRad(zenith)) +
            0.50572 * math.pow(96.07995 - zenith, -1.6364));
    final dni = 1.353 * math.pow(0.7, math.pow(airMass, 0.678));
    final irradiance = (dni / 0.947).clamp(0.0, 1.0);

    var projection = math.cos(GeoUtils.toRad(altitude));
    projection *= 1 - 0.7 * _smoothstep(55, 75, altitude);
    final horizonFade = _smoothstep(0, 5, altitude);
    return (irradiance * projection * horizonFade).clamp(0.0, 1.0);
  }

  /// Raw (cloud-free) intensity 0–1 for [seat] given the sun's angle relative
  /// to the heading (0 ahead, 90 right) and its altitude.
  static double seatIntensity(
    Seat seat,
    VehicleLayout layout,
    double relativeDeg,
    double altitude,
  ) {
    final base = altitudeFactor(altitude);
    if (base <= 0) return 0;

    final theta = GeoUtils.toRad(relativeDeg);
    final lateral = math.sin(theta); // + right
    final longitudinal = math.cos(theta); // + ahead

    double geometry;
    switch (seat.side) {
      case SeatSide.right:
        geometry = math.max(0, lateral) * (seat.isWindow ? 1.0 : 0.4);
      case SeatSide.left:
        geometry = math.max(0, -lateral) * (seat.isWindow ? 1.0 : 0.4);
      case SeatSide.middle:
        geometry = lateral.abs() * 0.22;
    }

    if (layout.hasWindshield && longitudinal > 0) {
      final reach = (1 - (seat.y - layout.firstRowY) / layout.windshieldReach)
          .clamp(0.0, 1.0);
      geometry = math.max(geometry, longitudinal * reach * 0.75);
    }
    if (layout.hasRearWindow && longitudinal < 0) {
      final reach = (1 - (layout.lastRowY - seat.y) / layout.rearWindowReach)
          .clamp(0.0, 1.0);
      geometry = math.max(geometry, -longitudinal * reach * 0.5);
    }

    final ambientNow = ambient * math.min(1.0, base * 4);
    return math.max(geometry * base, ambientNow);
  }

  /// 0–1 ventilation access (plan step 7).
  static double ventilation(Seat seat, VehicleLayout layout) {
    double v;
    switch (layout.type) {
      case VehicleType.train:
        v = 0.6;
      case VehicleType.bus:
        v = seat.isWindow ? 0.9 : (seat.isMiddle ? 0.3 : 0.5);
      case VehicleType.car4:
      case VehicleType.car5plus:
        v = seat.isWindow ? 0.85 : 0.3;
    }
    final isBackRow = switch (layout.type) {
      VehicleType.bus => seat.row == layout.rows,
      VehicleType.car5plus => seat.row == 3,
      _ => false,
    };
    if (isBackRow) v -= 0.2;
    return v.clamp(0.0, 1.0);
  }

  /// 0–10 comfort points: window view, front section, near an exit.
  static double comfort(Seat seat, VehicleLayout layout) {
    var c = 0.0;
    if (seat.isWindow) c += 5;
    final frontRows = math.max(1, (layout.rows / 3).ceil());
    if (seat.row <= frontRows) c += 3;
    if (layout.exitRows.contains(seat.row)) c += 2;
    return c;
  }

  static double _smoothstep(double edge0, double edge1, double x) {
    final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }
}
