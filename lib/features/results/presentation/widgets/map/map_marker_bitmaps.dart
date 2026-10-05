import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../weather/domain/entities/weather_data.dart';
import '../../../../weather/presentation/widgets/weather_icon_widget.dart';

/// Renders the custom Google Maps marker images (vehicle puck, sun pointer,
/// endpoints, weather chips) with the same look as the rest of the app.
class MapMarkerBitmaps {
  MapMarkerBitmaps._(this.vehicle, this.sunPointer, this.origin, this.destination);

  /// Arrow puck pointing up; rotate the marker to the heading.
  final BitmapDescriptor vehicle;

  /// Dashed ray with a sun at the top; rotate the marker to the sun azimuth.
  final BitmapDescriptor sunPointer;
  final BitmapDescriptor origin;
  final BitmapDescriptor destination;

  static const sunPointerSize = Size(132, 132);

  static Future<MapMarkerBitmaps> create(double dpr) async {
    final results = await Future.wait([
      _render(const Size(48, 48), dpr, _paintVehicle),
      _render(sunPointerSize, dpr, _paintSunPointer),
      _render(const Size(22, 22), dpr, _paintOrigin),
      _render(const Size(40, 40), dpr, _paintDestination),
    ]);
    return MapMarkerBitmaps._(results[0], results[1], results[2], results[3]);
  }

  static Future<BitmapDescriptor> weatherChip(
    double dpr, {
    required WeatherCondition condition,
    required double temperature,
    required bool night,
  }) {
    return _render(const Size(68, 32), dpr, (canvas, size) {
      final rect = RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(2),
        const Radius.circular(14),
      );
      canvas.drawRRect(
        rect.shift(const Offset(0, 1.5)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );
      canvas.drawRRect(rect, Paint()..color = AppColors.bgSecondary.withValues(alpha: 0.94));
      canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AppColors.borderStrong,
      );
      final icon = WeatherStyle.icon(condition, night: night);
      final glyph = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            fontSize: 16,
            color: WeatherStyle.iconColor(condition, night: night),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final label = TextPainter(
        text: TextSpan(
          text: '${temperature.round()}°',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final total = glyph.width + 4 + label.width;
      final x = (size.width - total) / 2;
      glyph.paint(canvas, Offset(x, (size.height - glyph.height) / 2));
      label.paint(canvas, Offset(x + glyph.width + 4, (size.height - label.height) / 2));
    });
  }

  static Future<BitmapDescriptor> _render(
    Size size,
    double dpr,
    void Function(Canvas canvas, Size size) paint,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    paint(canvas, size);
    final image = await recorder
        .endRecording()
        .toImage((size.width * dpr).ceil(), (size.height * dpr).ceil());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), imagePixelRatio: dpr);
  }

  static void _paintVehicle(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, 23, Paint()..color = AppColors.accentSun.withValues(alpha: 0.18));
    canvas.drawCircle(
      c,
      13,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(c, 12.5, Paint()..color = Colors.white);
    canvas.drawCircle(c, 10, Paint()..color = const Color(0xFF1C1F2A));
    final arrow = Path()
      ..moveTo(c.dx, c.dy - 7.5)
      ..lineTo(c.dx + 6, c.dy + 5.5)
      ..lineTo(c.dx, c.dy + 2.5)
      ..lineTo(c.dx - 6, c.dy + 5.5)
      ..close();
    canvas.drawPath(arrow, Paint()..color = AppColors.accentSun);
  }

  static void _paintSunPointer(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final dash = Paint()
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = AppColors.accentSun;
    for (var t = 18.0; t < 50; t += 7) {
      canvas.drawLine(Offset(c.dx, c.dy - t), Offset(c.dx, c.dy - math.min(t + 3.5, 50)), dash);
    }
    final sun = Offset(c.dx, c.dy - 57);
    canvas.drawCircle(sun, 10, Paint()..color = AppColors.accentSun.withValues(alpha: 0.3));
    canvas.drawCircle(
      sun,
      6,
      Paint()
        ..shader = const RadialGradient(colors: [Color(0xFFFFF1C2), AppColors.accentSun])
            .createShader(Rect.fromCircle(center: sun, radius: 6)),
    );
  }

  static void _paintOrigin(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(
      c,
      9,
      Paint()
        ..color = Colors.black54
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(c, 8.5, Paint()..color = Colors.white);
    canvas.drawCircle(c, 5.5, Paint()..color = AppColors.accentCool);
  }

  static void _paintDestination(Canvas canvas, Size size) {
    const icon = Icons.location_on_rounded;
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: 38,
          color: AppColors.accentHot,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height - tp.height));
  }
}
