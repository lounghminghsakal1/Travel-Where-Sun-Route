import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../domain/entities/seat.dart';
import '../../domain/entities/vehicle_layout.dart';

/// Pixel geometry of a vehicle drawn top-down, front pointing up.
class VehicleGeometry {
  VehicleGeometry._(this.layout, this.size, this.body, this.seatRects);

  final VehicleLayout layout;
  final Size size;
  final Rect body;
  final Map<String, RRect> seatRects;

  static const margin = 46.0;

  static Size canvasSize(VehicleLayout layout, double bodyWidth) =>
      Size(bodyWidth + margin * 2, bodyWidth * layout.lengthRatio + margin * 2);

  factory VehicleGeometry.compute(VehicleLayout layout, Size size) {
    final bodyW = size.width - margin * 2;
    final bodyH = bodyW * layout.lengthRatio;
    final body = Rect.fromLTWH(margin, margin, bodyW, bodyH);
    final w = layout.seatWidth * bodyW;
    final h = layout.seatHeight * bodyH;
    final rects = <String, RRect>{
      for (final s in layout.seatMap)
        s.id: RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(body.left + s.x * bodyW, body.top + s.y * bodyH),
            width: w,
            height: h,
          ),
          Radius.circular(math.min(w, h) * 0.22),
        ),
    };
    return VehicleGeometry._(layout, size, body, rects);
  }

  String? seatAt(Offset p) {
    for (final e in seatRects.entries) {
      if (e.value.outerRect.inflate(3).contains(p)) return e.key;
    }
    return null;
  }
}

enum SeatColorMode { live, score }

class VehiclePainter extends CustomPainter {
  VehiclePainter({
    required this.geometry,
    required this.exposure,
    required this.scores,
    required this.mode,
    required this.relativeAngle,
    required this.altitude,
    required this.sunStrength,
    required this.pulse,
    this.selectedId,
    this.highlighted = const {},
    this.medals = const {},
  });

  final VehicleGeometry geometry;

  /// Current weather-adjusted intensity per seat (0–1).
  final Map<String, double> exposure;

  /// Overall score per seat (0–100).
  final Map<String, double> scores;
  final SeatColorMode mode;

  /// Sun azimuth relative to heading (0 ahead, 90 right).
  final double relativeAngle;
  final double altitude;

  /// 0–1 how strong the sunlight is right now (altitude × clouds).
  final double sunStrength;

  /// 0–1 animation phase for the sun glow.
  final double pulse;
  final String? selectedId;
  final Set<String> highlighted;

  /// seatId → 1/2/3 medal.
  final Map<String, int> medals;

  VehicleLayout get layout => geometry.layout;
  Rect get body => geometry.body;
  bool get sunUp => altitude > 0;

  @override
  void paint(Canvas canvas, Size size) {
    final theta = GeoUtils.toRad(relativeAngle);
    final toSun = Offset(math.sin(theta), -math.cos(theta));
    final bodyShape = _bodyRRect();

    if (sunUp) _paintRays(canvas, size, toSun);
    if (sunUp) _paintShadow(canvas, bodyShape, toSun);
    _paintWheels(canvas);
    _paintBody(canvas, bodyShape);
    _paintGlass(canvas, toSun);
    if (sunUp) _paintInteriorLight(canvas, bodyShape, toSun);
    _paintInterior(canvas);
    _paintSeats(canvas);
    _paintFrontLabel(canvas);
    if (sunUp) _paintSun(canvas, size, toSun);
  }

  // ------------------------------------------------------------------ body

  RRect _bodyRRect() {
    final w = body.width;
    switch (layout.type) {
      case VehicleType.bus:
        return RRect.fromRectAndCorners(
          body,
          topLeft: Radius.circular(w * 0.16),
          topRight: Radius.circular(w * 0.16),
          bottomLeft: Radius.circular(w * 0.07),
          bottomRight: Radius.circular(w * 0.07),
        );
      case VehicleType.train:
        return RRect.fromRectAndRadius(body, Radius.circular(w * 0.08));
      case VehicleType.car4:
      case VehicleType.car5plus:
        return RRect.fromRectAndCorners(
          body,
          topLeft: Radius.elliptical(w * 0.38, w * 0.5),
          topRight: Radius.elliptical(w * 0.38, w * 0.5),
          bottomLeft: Radius.elliptical(w * 0.3, w * 0.28),
          bottomRight: Radius.elliptical(w * 0.3, w * 0.28),
        );
    }
  }

  void _paintRays(Canvas canvas, Size size, Offset toSun) {
    final strength = sunStrength.clamp(0.0, 1.0);
    if (strength <= 0.01) return;
    final center = size.center(Offset.zero);
    final diag = size.longestSide;
    final rayDir = -toSun;
    final perp = Offset(-rayDir.dy, rayDir.dx);
    final shaderRect = Rect.fromPoints(center + toSun * diag / 2, center - toSun * diag / 2);
    final glow = 0.75 + pulse * 0.25;

    // Broad wash.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(toSun.dx, toSun.dy),
          end: Alignment(-toSun.dx, -toSun.dy),
          colors: [
            AppColors.accentSun.withValues(alpha: 0.16 * strength * glow),
            AppColors.accentSun.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );

    // Parallel rays.
    final rayPaint = Paint()
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          AppColors.accentSun.withValues(alpha: 0.5 * strength * glow),
          AppColors.accentSun.withValues(alpha: 0.0),
        ],
      ).createShader(shaderRect);
    const spacing = 17.0;
    final n = (diag / spacing).ceil();
    for (var k = -n; k <= n; k++) {
      final o = center + perp * (k * spacing);
      canvas.drawLine(o + toSun * diag, o - toSun * diag * 0.2, rayPaint);
    }
  }

  void _paintShadow(Canvas canvas, RRect shape, Offset toSun) {
    final alt = altitude.clamp(3.0, 89.0);
    final len = (16 / math.tan(GeoUtils.toRad(alt))).clamp(4.0, 34.0) * sunStrength.clamp(0.3, 1.0);
    canvas.drawRRect(
      shape.shift(-toSun * len),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
  }

  void _paintWheels(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFF0A0B10);
    final w = body.width;
    final wheelW = w * (layout.type.isCar ? 0.075 : 0.06);
    final wheelH = body.height * (layout.type.isCar ? 0.13 : 0.075);
    final ys = switch (layout.type) {
      VehicleType.bus => [0.17, 0.78],
      VehicleType.train => [0.12, 0.88],
      VehicleType.car4 => [0.21, 0.79],
      VehicleType.car5plus => [0.2, 0.8],
    };
    for (final fy in ys) {
      for (final left in [true, false]) {
        final cx = left ? body.left - wheelW * 0.35 : body.right + wheelW * 0.35;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(cx, body.top + body.height * fy),
              width: wheelW,
              height: wheelH,
            ),
            Radius.circular(wheelW * 0.4),
          ),
          paint,
        );
      }
    }
    // Mirrors.
    if (layout.type != VehicleType.train) {
      final my = body.top + body.height * (layout.type == VehicleType.bus ? 0.035 : 0.33);
      final mirror = Paint()..color = AppColors.bgElevated;
      for (final left in [true, false]) {
        final x = left ? body.left - 7 : body.right + 7;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, my), width: 12, height: 7), mirror);
      }
    }
  }

  void _paintBody(Canvas canvas, RRect shape) {
    canvas.drawRRect(
      shape,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF353B4E), Color(0xFF262A38), Color(0xFF1F2330)],
        ).createShader(body),
    );
    // Inner cabin floor.
    final inset = body.width * 0.045;
    canvas.drawRRect(
      shape.deflate(inset),
      Paint()..color = const Color(0xFF1B1E29),
    );
    canvas.drawRRect(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.14),
    );
  }

  void _paintGlass(Canvas canvas, Offset toSun) {
    final w = body.width;
    final glass = Paint()..color = const Color(0xFF8EC5FF).withValues(alpha: 0.28);
    final lateral = toSun.dx; // + right
    final ahead = -toSun.dy; // + front

    Paint litGlass(double amount) {
      final a = (amount * sunStrength).clamp(0.0, 1.0);
      return Paint()
        ..color = Color.lerp(
          const Color(0xFF8EC5FF).withValues(alpha: 0.28),
          AppColors.accentSun.withValues(alpha: 0.9),
          sunUp ? a : 0,
        )!;
    }

    // Side windows.
    final top = body.top + body.height * (layout.type.isCar ? 0.3 : (layout.type == VehicleType.bus ? 0.06 : 0.05));
    final bottom = body.top + body.height * (layout.type.isCar ? 0.78 : 0.95);
    const stripW = 3.2;
    final inset = w * 0.012;
    for (final left in [true, false]) {
      final x = left ? body.left + inset : body.right - inset - stripW;
      final amount = left ? math.max(0.0, -lateral) : math.max(0.0, lateral);
      final paint = litGlass(amount);
      final doors = [
        for (final dy in layout.doorYs)
          if (layout.type == VehicleType.train || layout.doorOnLeft == left) dy,
      ];
      var y = top;
      for (final dy in doors..sort()) {
        final doorTop = body.top + body.height * dy - body.height * 0.025;
        final doorBottom = body.top + body.height * dy + body.height * 0.025;
        if (doorTop > y) {
          canvas.drawRRect(
            RRect.fromLTRBR(x, y, x + stripW, math.min(doorTop, bottom), const Radius.circular(2)),
            paint,
          );
        }
        y = math.max(y, doorBottom);
      }
      if (y < bottom) {
        canvas.drawRRect(RRect.fromLTRBR(x, y, x + stripW, bottom, const Radius.circular(2)), paint);
      }
      // Door markers.
      for (final dy in doors) {
        final cy = body.top + body.height * dy;
        canvas.drawLine(
          Offset(x + stripW / 2, cy - body.height * 0.02),
          Offset(x + stripW / 2, cy + body.height * 0.02),
          Paint()
            ..color = AppColors.textMuted
            ..strokeWidth = 1,
        );
      }
    }

    // Windshield.
    if (layout.hasWindshield) {
      final Rect r;
      if (layout.type == VehicleType.bus) {
        r = Rect.fromLTRB(body.left + w * 0.1, body.top + w * 0.035, body.right - w * 0.1, body.top + w * 0.1);
      } else {
        r = Rect.fromLTRB(
          body.left + w * 0.14,
          body.top + body.height * (layout.type == VehicleType.car4 ? 0.25 : 0.215),
          body.right - w * 0.14,
          body.top + body.height * (layout.type == VehicleType.car4 ? 0.31 : 0.265),
        );
      }
      final path = Path()
        ..moveTo(r.left + r.width * 0.06, r.top)
        ..lineTo(r.right - r.width * 0.06, r.top)
        ..quadraticBezierTo(r.right, r.top, r.right, r.bottom)
        ..lineTo(r.left, r.bottom)
        ..quadraticBezierTo(r.left, r.top, r.left + r.width * 0.06, r.top)
        ..close();
      canvas.drawPath(path, ahead > 0 ? litGlass(ahead) : glass);
    }
    if (layout.hasRearWindow) {
      final r = Rect.fromLTRB(
        body.left + w * 0.17,
        body.top + body.height * (layout.type == VehicleType.car4 ? 0.8 : 0.83),
        body.right - w * 0.17,
        body.top + body.height * (layout.type == VehicleType.car4 ? 0.85 : 0.875),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(5)),
        ahead < 0 ? litGlass(-ahead) : glass,
      );
    }
  }

  void _paintInteriorLight(Canvas canvas, RRect shape, Offset toSun) {
    final a = 0.22 * sunStrength;
    if (a <= 0.01) return;
    final c = body.center;
    final reach = Offset(toSun.dx * body.width / 2, toSun.dy * body.height / 2);
    final edge = c + reach;
    canvas.save();
    canvas.clipRRect(shape);
    canvas.drawRect(
      body,
      Paint()
        ..shader = LinearGradient(
          colors: [AppColors.accentSun.withValues(alpha: a), AppColors.accentSun.withValues(alpha: 0)],
        ).createShader(Rect.fromPoints(edge, c - reach * 0.2)),
    );
    canvas.restore();
  }

  void _paintInterior(Canvas canvas) {
    final w = body.width;
    final muted = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.2;

    if (layout.type == VehicleType.bus || layout.type == VehicleType.train) {
      // Dashed aisle.
      final x = body.center.dx;
      final y0 = body.top + body.height * (layout.type == VehicleType.bus ? 0.16 : 0.06);
      final y1 = body.top + body.height * (layout.type == VehicleType.bus ? 0.92 : 0.94);
      for (var y = y0; y < y1; y += 9) {
        canvas.drawLine(Offset(x, y), Offset(x, math.min(y + 4, y1)), muted);
      }
    }

    if (layout.type == VehicleType.train) {
      final tablePaint = Paint()..color = const Color(0xFF39405A);
      for (final ty in layout.tableYs) {
        final y = body.top + body.height * ty;
        for (final left in [true, false]) {
          final x0 = left ? body.left + w * 0.06 : body.left + w * 0.6;
          final x1 = left ? body.left + w * 0.4 : body.right - w * 0.06;
          canvas.drawRRect(
            RRect.fromLTRBR(x0, y - 3.5, x1, y + 3.5, const Radius.circular(3)),
            tablePaint,
          );
        }
      }
      // Vestibules.
      for (final ty in [0.025, 0.975]) {
        final y = body.top + body.height * ty;
        canvas.drawLine(Offset(body.left + 8, y), Offset(body.right - 8, y), muted);
      }
    }

    // Steering wheel + dashboard.
    for (final s in layout.seatMap.where((s) => s.isDriver)) {
      final r = geometry.seatRects[s.id]!.outerRect;
      final wheelC = Offset(r.center.dx, r.top - r.height * 0.42);
      canvas.drawCircle(
        wheelC,
        r.width * 0.28,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = const Color(0xFF8A93A6),
      );
      if (layout.type == VehicleType.bus) {
        final dashY = r.top - r.height * 0.95;
        canvas.drawLine(Offset(body.left + w * 0.08, dashY), Offset(body.right - w * 0.08, dashY), muted);
      }
    }
  }

  // ----------------------------------------------------------------- seats

  void _paintSeats(Canvas canvas) {
    for (final seat in layout.seatMap) {
      final rr = geometry.seatRects[seat.id]!;
      final Color fill;
      if (seat.isDriver) {
        fill = const Color(0xFF3A4054);
      } else if (mode == SeatColorMode.live) {
        fill = sunUp || (exposure[seat.id] ?? 0) > 0
            ? ColorUtils.exposureColor((exposure[seat.id] ?? 0) / 0.8)
            : const Color(0xFF4F6A8F);
      } else {
        fill = ColorUtils.scoreColor(scores[seat.id] ?? 0);
      }

      final isSelected = seat.id == selectedId;
      final isHighlighted = highlighted.contains(seat.id);
      if (isSelected) {
        canvas.drawRRect(
          rr.inflate(4),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }

      canvas.drawRRect(
        rr,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(fill, Colors.white, 0.12)!, fill],
          ).createShader(rr.outerRect),
      );

      // Backrest on the side the passenger leans against.
      final facesRear = layout.type == VehicleType.train && seat.row.isOdd;
      final r = rr.outerRect;
      final backH = r.height * 0.26;
      final back = facesRear
          ? Rect.fromLTRB(r.left + 1.5, r.top + 1.5, r.right - 1.5, r.top + backH)
          : Rect.fromLTRB(r.left + 1.5, r.bottom - backH, r.right - 1.5, r.bottom - 1.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(back, Radius.circular(rr.tlRadiusX * 0.7)),
        Paint()..color = Color.lerp(fill, Colors.black, 0.28)!,
      );

      if (isSelected || isHighlighted) {
        canvas.drawRRect(
          rr.inflate(isSelected ? 2 : 1.5),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSelected ? 2.4 : 1.8
            ..color = isSelected ? Colors.white : AppColors.textPrimary.withValues(alpha: 0.9),
        );
      }

      _paintSeatLabel(canvas, seat, r, fill, facesRear);

      final medal = medals[seat.id];
      if (medal != null) _paintMedal(canvas, r.topRight, medal);
    }
  }

  void _paintSeatLabel(Canvas canvas, Seat seat, Rect r, Color fill, bool facesRear) {
    final text = seat.isDriver ? '' : seat.id;
    if (text.isEmpty) return;
    final fontSize = math.min(10.5, r.height * 0.34).clamp(7.0, 10.5);
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: ColorUtils.onColor(fill).withValues(alpha: 0.85),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: r.width);
    final dy = facesRear ? r.height * 0.1 : -r.height * 0.1;
    tp.paint(canvas, r.center + Offset(-tp.width / 2, -tp.height / 2 + dy));
  }

  void _paintMedal(Canvas canvas, Offset at, int rank) {
    final color = switch (rank) {
      1 => AppColors.gold,
      2 => AppColors.silver,
      _ => AppColors.bronze,
    };
    final c = at + const Offset(-1, 1);
    canvas.drawCircle(c, 7.5, Paint()..color = const Color(0xFF14161D));
    canvas.drawCircle(c, 6.2, Paint()..color = color);
    final tp = TextPainter(
      text: TextSpan(
        text: '$rank',
        style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Color(0xFF14161D)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  void _paintFrontLabel(Canvas canvas) {
    final tp = TextPainter(
      text: const TextSpan(
        text: '▲  FRONT',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: AppColors.textMuted),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(body.center.dx - tp.width / 2, body.top - tp.height - 8));
  }

  // ------------------------------------------------------------------- sun

  void _paintSun(Canvas canvas, Size size, Offset toSun) {
    // Place the sun where the direction from the centre leaves the margin box.
    final c = size.center(Offset.zero);
    final box = body.inflate(VehicleGeometry.margin * 0.55);
    final tx = toSun.dx.abs() < 1e-6 ? double.infinity : (box.width / 2) / toSun.dx.abs();
    final ty = toSun.dy.abs() < 1e-6 ? double.infinity : (box.height / 2) / toSun.dy.abs();
    final t = math.min(tx, ty);
    final pos = Offset(
      (c.dx + toSun.dx * t).clamp(16.0, size.width - 16),
      (c.dy + toSun.dy * t).clamp(16.0, size.height - 16),
    );

    final strength = (0.45 + sunStrength * 0.55).clamp(0.0, 1.0);
    final glowR = 20 + pulse * 5;
    canvas.drawCircle(
      pos,
      glowR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.accentSun.withValues(alpha: 0.55 * strength),
            AppColors.accentSun.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: pos, radius: glowR)),
    );
    final rayPaint = Paint()
      ..color = AppColors.accentSun.withValues(alpha: 0.85 * strength)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + pulse * 0.3;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(pos + d * 11, pos + d * (14.5 + pulse * 1.5), rayPaint);
    }
    canvas.drawCircle(
      pos,
      8,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFF3C4), AppColors.accentSun],
        ).createShader(Rect.fromCircle(center: pos, radius: 8)),
    );
  }

  @override
  bool shouldRepaint(VehiclePainter old) => true;
}
