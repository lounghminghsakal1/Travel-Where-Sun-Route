import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
    );
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    const scheme = ColorScheme.dark(
      primary: AppColors.accentSun,
      onPrimary: Color(0xFF241800),
      secondary: AppColors.accentShade,
      onSecondary: Colors.white,
      surface: AppColors.bgSecondary,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.bgCard,
      surfaceContainerHigh: AppColors.bgCard,
      surfaceContainer: AppColors.bgSecondary,
      error: AppColors.accentHot,
      outline: AppColors.borderStrong,
      outlineVariant: AppColors.border,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      canvasColor: AppColors.bgPrimary,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.bgElevated,
        contentTextStyle: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
        actionTextColor: AppColors.accentSun,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bgSecondary,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgSecondary,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgCard,
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accentSun, width: 1.4),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentSun,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.bgSecondary,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.bgCard,
        headerForegroundColor: AppColors.textPrimary,
        weekdayStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        dayForegroundColor: WidgetStateColor.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return const Color(0xFF241800);
          if (s.contains(WidgetState.disabled)) return AppColors.textMuted;
          return AppColors.textPrimary;
        }),
        dayBackgroundColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.accentSun : Colors.transparent,
        ),
        todayForegroundColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected) ? const Color(0xFF241800) : AppColors.accentSun,
        ),
        todayBorder: const BorderSide(color: AppColors.accentSun),
        yearForegroundColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected) ? const Color(0xFF241800) : AppColors.textPrimary,
        ),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: AppColors.accentSun),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      // Explicit colours: the Material 3 defaults derive selected text from
      // container colours this scheme doesn't define, giving dark-on-dark.
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.bgSecondary,
        helpTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: AppColors.textSecondary,
        ),
        hourMinuteShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        hourMinuteColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.accentSun.withValues(alpha: 0.22)
              : AppColors.bgCard,
        ),
        hourMinuteTextColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.accentSun : AppColors.textPrimary,
        ),
        hourMinuteTextStyle: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w500),
        dayPeriodColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.accentSun.withValues(alpha: 0.22)
              : Colors.transparent,
        ),
        dayPeriodTextColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.accentSun : AppColors.textSecondary,
        ),
        dayPeriodBorderSide: const BorderSide(color: AppColors.borderStrong),
        dialBackgroundColor: AppColors.bgCard,
        dialHandColor: AppColors.accentSun,
        dialTextColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected) ? const Color(0xFF241800) : AppColors.textPrimary,
        ),
        entryModeIconColor: AppColors.textSecondary,
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: AppColors.accentSun),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: AppColors.bgCard,
          border: InputBorder.none,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
