import 'package:flutter/material.dart';

import '../../../sun_analysis/domain/entities/route_point.dart';
import 'weather_icon_widget.dart';

/// Paints the weather timeline strip: one colour per condition, darkened at
/// night, merged into runs so it reads as clean segments.
class WeatherBarPainter {
  const WeatherBarPainter._();

  static const _night = Color(0xFF141A33);

  static void paint(Canvas canvas, Rect rect, List<RoutePoint> points, {double radius = 4}) {
    if (points.length < 2) return;
    final start = points.first.timestamp;
    final totalMs = points.last.timestamp.difference(start).inMilliseconds.toDouble();
    if (totalMs <= 0) return;

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

    Color colorAt(RoutePoint p) {
      final base = WeatherStyle.color(p.weather?.condition);
      return p.sun.isUp ? base : Color.lerp(base, _night, 0.62)!;
    }

    double xOf(RoutePoint p) =>
        rect.left + rect.width * p.timestamp.difference(start).inMilliseconds / totalMs;

    var runStart = points.first;
    var runColor = colorAt(runStart);
    for (var i = 1; i < points.length; i++) {
      final c = colorAt(points[i]);
      final isLast = i == points.length - 1;
      if (c != runColor || isLast) {
        final x0 = xOf(runStart);
        final x1 = isLast ? rect.right : xOf(points[i]);
        canvas.drawRect(
          Rect.fromLTRB(x0, rect.top, x1 + 0.5, rect.bottom),
          Paint()..color = runColor,
        );
        runStart = points[i];
        runColor = c;
      }
    }

    // Soft top highlight for depth.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.18), Colors.transparent],
        ).createShader(rect),
    );
    canvas.restore();
  }
}
