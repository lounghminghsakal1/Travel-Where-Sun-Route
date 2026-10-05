import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/entities/weather_data.dart';

class WeatherStyle {
  const WeatherStyle._();

  static IconData icon(WeatherCondition? c, {bool night = false}) => switch (c) {
        null => Icons.cloud_off_rounded,
        WeatherCondition.clear => night ? Icons.nightlight_round : Icons.wb_sunny_rounded,
        WeatherCondition.partlyCloudy => night ? Icons.nights_stay_rounded : Icons.wb_cloudy_rounded,
        WeatherCondition.cloudy => Icons.cloud_rounded,
        WeatherCondition.overcast => Icons.cloud_rounded,
        WeatherCondition.rain => Icons.water_drop_rounded,
        WeatherCondition.storm => Icons.thunderstorm_rounded,
        WeatherCondition.fog => Icons.foggy,
        WeatherCondition.snow => Icons.ac_unit_rounded,
      };

  /// Timeline colours from the plan's weather bar spec.
  static Color color(WeatherCondition? c) => switch (c) {
        null => const Color(0xFF3A3F4F),
        WeatherCondition.clear => const Color(0xFFFFB830),
        WeatherCondition.partlyCloudy => const Color(0xFFB9C0CC),
        WeatherCondition.cloudy => const Color(0xFF8A93A6),
        WeatherCondition.overcast => const Color(0xFF5D6577),
        WeatherCondition.rain => const Color(0xFF4A9EFF),
        WeatherCondition.storm => const Color(0xFF3B4FC4),
        WeatherCondition.fog => const Color(0xFFE3E7EE),
        WeatherCondition.snow => const Color(0xFFDDEBFF),
      };

  static Color iconColor(WeatherCondition? c, {bool night = false}) {
    if (night && (c == WeatherCondition.clear || c == WeatherCondition.partlyCloudy)) {
      return const Color(0xFFC9D4FF);
    }
    if (c == WeatherCondition.overcast) return const Color(0xFF9AA3B5);
    return color(c);
  }
}

/// Weather glyph with a gentle float.
class WeatherIcon extends StatelessWidget {
  const WeatherIcon({
    super.key,
    required this.condition,
    this.night = false,
    this.size = 24,
    this.animate = true,
  });

  final WeatherCondition? condition;
  final bool night;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      WeatherStyle.icon(condition, night: night),
      size: size,
      color: WeatherStyle.iconColor(condition, night: night),
    );
    if (!animate) return icon;
    return icon
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -1.5, end: 1.5, duration: 1800.ms, curve: Curves.easeInOut);
  }
}
