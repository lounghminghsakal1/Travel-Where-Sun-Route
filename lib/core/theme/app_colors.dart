import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const bgPrimary = Color(0xFF0F1117);
  static const bgSecondary = Color(0xFF1A1D27);
  static const bgCard = Color(0xFF232734);
  static const bgElevated = Color(0xFF2B3040);
  static const border = Color(0x14FFFFFF);
  static const borderStrong = Color(0x26FFFFFF);

  static const textPrimary = Color(0xFFE8EAED);
  static const textSecondary = Color(0xFF9AA0B0);
  static const textMuted = Color(0xFF6B7183);

  static const accentSun = Color(0xFFFFB830);
  static const accentShade = Color(0xFF4A9EFF);
  static const accentHot = Color(0xFFFF6B6B);
  static const accentCool = Color(0xFF51CF66);
  static const accentRain = Color(0xFF748FFC);
  static const accentWarm = Color(0xFFFF8A3D);

  static const gold = Color(0xFFFFC94D);
  static const silver = Color(0xFFC9D1E0);
  static const bronze = Color(0xFFE09A62);

  static const gradientSun = LinearGradient(
    colors: [Color(0xFFFFB830), Color(0xFFFF6B6B)],
  );
  static const gradientShade = LinearGradient(
    colors: [Color(0xFF4A9EFF), Color(0xFF51CF66)],
  );
  static const gradientSunButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFC14D), Color(0xFFFF8A3D), Color(0xFFFF6B6B)],
    stops: [0, 0.55, 1],
  );
  static const gradientDusk = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2A1F3D), Color(0xFF1A1830), bgPrimary],
    stops: [0, 0.45, 1],
  );
}
