class SunPosition {
  const SunPosition({required this.azimuth, required this.altitude});

  /// Degrees clockwise from north.
  final double azimuth;

  /// Degrees above the horizon.
  final double altitude;

  bool get isUp => altitude > 0;
}

/// Where the sun is relative to the vehicle.
enum SunSide {
  none('Below horizon'),
  front('Ahead'),
  frontRight('Front right'),
  right('Right'),
  rearRight('Rear right'),
  rear('Behind'),
  rearLeft('Rear left'),
  left('Left'),
  frontLeft('Front left'),
  top('Overhead');

  const SunSide(this.label);
  final String label;

  /// Maps a relative angle (sun azimuth minus heading) to a side, using the
  /// bands from the plan.
  static SunSide fromRelative(double relativeDeg, double altitude) {
    if (altitude <= 0) return SunSide.none;
    if (altitude > 65) return SunSide.top;
    final a = relativeDeg % 360;
    if (a >= 350 || a < 10) return SunSide.front;
    if (a < 80) return SunSide.frontRight;
    if (a < 100) return SunSide.right;
    if (a < 170) return SunSide.rearRight;
    if (a < 190) return SunSide.rear;
    if (a < 260) return SunSide.rearLeft;
    if (a < 280) return SunSide.left;
    return SunSide.frontLeft;
  }

  bool get isRightish => this == right || this == frontRight || this == rearRight;
  bool get isLeftish => this == left || this == frontLeft || this == rearLeft;
}
