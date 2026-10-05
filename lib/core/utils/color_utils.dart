import 'package:flutter/material.dart';

import '../../features/sun_analysis/domain/entities/sun_position.dart';
import '../theme/app_colors.dart';

class ColorUtils {
  const ColorUtils._();

  static const _ramp = [
    (0.0, Color(0xFF3FBF6A)),
    (0.2, Color(0xFF8BD45A)),
    (0.38, Color(0xFFFFC94D)),
    (0.6, Color(0xFFFF9445)),
    (1.0, Color(0xFFFF5C5C)),
  ];

  /// Green (shade) → yellow → red (direct sun) for an intensity 0–1.
  static Color exposureColor(double intensity) {
    final v = intensity.clamp(0.0, 1.0);
    for (var i = 0; i < _ramp.length - 1; i++) {
      final (a, ca) = _ramp[i];
      final (b, cb) = _ramp[i + 1];
      if (v <= b) return Color.lerp(ca, cb, (v - a) / (b - a))!;
    }
    return _ramp.last.$2;
  }

  /// Score 0–100 → red (poor) … green (great).
  static Color scoreColor(double score) =>
      exposureColor(1 - ((score - 35) / 55).clamp(0.0, 1.0));

  static String exposureLabel(double intensity) {
    if (intensity < 0.15) return 'Low';
    if (intensity < 0.45) return 'Medium';
    return 'High';
  }

  /// Route colouring by which side of the vehicle gets the sun.
  static Color sunSideColor(SunSide side, double strength) {
    if (side == SunSide.none || strength < 0.12) return AppColors.accentShade;
    if (side.isLeftish) return AppColors.accentSun;
    if (side.isRightish) return AppColors.accentHot;
    if (side == SunSide.top) return const Color(0xFFB58CFF);
    return const Color(0xFFFFE08A);
  }

  static Color onColor(Color background) =>
      background.computeLuminance() > 0.45 ? const Color(0xFF14161D) : Colors.white;
}
