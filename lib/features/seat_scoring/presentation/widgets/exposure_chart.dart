import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../sun_analysis/domain/entities/route_point.dart';
import '../../../weather/presentation/widgets/weather_bar.dart';

/// Area chart of one seat's sun intensity across the journey, with night
/// shading, a weather strip and the current playhead.
class ExposureChart extends StatelessWidget {
  const ExposureChart({
    super.key,
    required this.points,
    required this.series,
    required this.progress,
    this.height = 150,
  });

  final List<RoutePoint> points;
  final List<double> series;
  final double progress;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _ExposurePainter(points, series, progress),
      ),
    );
  }
}

class _ExposurePainter extends CustomPainter {
  _ExposurePainter(this.points, this.series, this.progress);
  final List<RoutePoint> points;
  final List<double> series;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    const labelH = 16.0;
    const barH = 6.0;
    final chart = Rect.fromLTRB(0, 6, size.width, size.height - labelH - barH - 8);
    final start = points.first.timestamp;
    final total = points.last.timestamp.difference(start).inMilliseconds.toDouble();
    double xOf(int i) => chart.left + chart.width * points[i].timestamp.difference(start).inMilliseconds / total;
    double yOf(double v) => chart.bottom - chart.height * (v / 0.8).clamp(0.0, 1.0);

    // Night shading.
    for (var i = 0; i < points.length - 1; i++) {
      if (!points[i].sun.isUp) {
        canvas.drawRect(
          Rect.fromLTRB(xOf(i), chart.top, xOf(i + 1) + 0.5, chart.bottom),
          Paint()..color = const Color(0xFF141A33).withValues(alpha: 0.7),
        );
      }
    }

    // Grid.
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (final f in [0.0, 0.5, 1.0]) {
      final y = chart.bottom - chart.height * f;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
    }

    // Area.
    final line = Path()..moveTo(xOf(0), yOf(series[0]));
    for (var i = 1; i < points.length; i++) {
      line.lineTo(xOf(i), yOf(series[i]));
    }
    final area = Path.from(line)
      ..lineTo(chart.right, chart.bottom)
      ..lineTo(chart.left, chart.bottom)
      ..close();
    final ramp = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        ColorUtils.exposureColor(0),
        ColorUtils.exposureColor(0.45),
        ColorUtils.exposureColor(1),
      ],
    );
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [for (final c in ramp.colors) c.withValues(alpha: 0.3)],
        ).createShader(chart),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..shader = ramp.createShader(chart),
    );

    // Weather strip.
    final bar = Rect.fromLTRB(chart.left, chart.bottom + 6, chart.right, chart.bottom + 6 + barH);
    WeatherBarPainter.paint(canvas, bar, points, radius: 3);

    // Playhead.
    final px = chart.left + chart.width * progress;
    canvas.drawLine(
      Offset(px, chart.top),
      Offset(px, bar.bottom),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..strokeWidth = 1.4,
    );

    // Time labels.
    for (final f in [0.0, 0.5, 1.0]) {
      final t = start.add(Duration(milliseconds: (total * f).round()));
      final tp = TextPainter(
        text: TextSpan(
          text: TimeUtils.time(t),
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = (chart.left + chart.width * f - tp.width * f).clamp(0.0, size.width - tp.width);
      tp.paint(canvas, Offset(x, size.height - labelH + 2));
    }
  }

  @override
  bool shouldRepaint(_ExposurePainter old) =>
      old.progress != progress || old.series != series;
}
