import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../results/presentation/providers/results_provider.dart';

/// Frosted compass showing the vehicle heading and where the sun is.
class SunDirectionOverlay extends ConsumerWidget {
  const SunDirectionOverlay({super.key, this.size = 92});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frame = ref.watch(journeyFrameProvider);
    if (frame == null) return const SizedBox.shrink();
    final up = frame.sun.isUp;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bgSecondary.withValues(alpha: 0.7),
                border: Border.all(color: AppColors.border),
              ),
              child: CustomPaint(
                painter: _CompassPainter(
                  heading: frame.bearing,
                  sunAzimuth: frame.sun.azimuth,
                  sunUp: up,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.bgSecondary.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Text(
              up
                  ? '${frame.sun.azimuth.round()}° · ${frame.sun.altitude.round()}° up'
                  : 'Sun set',
              style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({required this.heading, required this.sunAzimuth, required this.sunUp});

  final double heading;
  final double sunAzimuth;
  final bool sunUp;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final ringR = r - 12;

    // Ticks every 30°, cardinal letters.
    final tick = Paint()
      ..color = AppColors.textMuted
      ..strokeWidth = 1;
    for (var d = 0; d < 360; d += 30) {
      final a = GeoUtils.toRad(d.toDouble());
      final dir = Offset(math.sin(a), -math.cos(a));
      final len = d % 90 == 0 ? 0 : 4;
      if (len > 0) canvas.drawLine(c + dir * (ringR - len), c + dir * ringR, tick);
    }
    const letters = {'N': 0.0, 'E': 90.0, 'S': 180.0, 'W': 270.0};
    letters.forEach((label, deg) {
      final a = GeoUtils.toRad(deg);
      final pos = c + Offset(math.sin(a), -math.cos(a)) * (ringR - 2);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: label == 'N' ? AppColors.accentHot : AppColors.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    });

    // Sun line + glyph on the ring.
    final sa = GeoUtils.toRad(sunAzimuth);
    final sunDir = Offset(math.sin(sa), -math.cos(sa));
    final sunPos = c + sunDir * (ringR + 3);
    if (sunUp) {
      canvas.drawLine(
        c,
        sunPos,
        Paint()
          ..shader = LinearGradient(
            colors: [AppColors.accentSun.withValues(alpha: 0), AppColors.accentSun.withValues(alpha: 0.8)],
          ).createShader(Rect.fromPoints(c, sunPos))
          ..strokeWidth = 2,
      );
      canvas.drawCircle(sunPos, 9, Paint()..color = AppColors.accentSun.withValues(alpha: 0.25));
      canvas.drawCircle(sunPos, 5.5, Paint()..color = AppColors.accentSun);
    } else {
      canvas.drawCircle(sunPos, 4.5, Paint()..color = AppColors.textMuted);
    }

    // Vehicle heading arrow.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(GeoUtils.toRad(heading));
    final arrow = Path()
      ..moveTo(0, -ringR + 14)
      ..lineTo(9, 10)
      ..lineTo(0, 5)
      ..lineTo(-9, 10)
      ..close();
    canvas.drawShadow(arrow, Colors.black, 3, false);
    canvas.drawPath(arrow, Paint()..color = Colors.white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CompassPainter old) =>
      old.heading != heading || old.sunAzimuth != sunAzimuth || old.sunUp != sunUp;
}
