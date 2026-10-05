import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../seat_scoring/domain/usecases/exposure_model.dart';
import '../../../sun_analysis/domain/entities/journey_stats.dart';
import '../../../weather/presentation/widgets/weather_bar.dart';
import '../../../weather/presentation/widgets/weather_icon_widget.dart';
import '../providers/results_provider.dart';
import '../providers/trip_analysis.dart';
import 'play_controls_widget.dart';

/// Fixed height so the panel can be pinned in a sliver header.
const double kScrubberPanelHeight = 186;

/// Time scrubber: current position readout, sun-altitude + weather timeline
/// with a draggable playhead, and playback controls.
class TimeScrubberPanel extends ConsumerWidget {
  const TimeScrubberPanel({super.key, required this.analysis});
  final TripAnalysis analysis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frame = ref.watch(journeyFrameProvider);
    if (frame == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoRow(frame: frame, analysis: analysis),
        const SizedBox(height: 10),
        _Timeline(analysis: analysis, progress: frame.progress),
        const SizedBox(height: 4),
        _TickLabels(analysis: analysis),
        const SizedBox(height: 6),
        PlayControlsWidget(analysis: analysis),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.frame, required this.analysis});
  final JourneyFrame frame;
  final TripAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final place = frame.placeName;
    final where = frame.progress <= 0.001
        ? 'Departing ${analysis.request.origin.name}'
        : frame.progress >= 0.999
            ? 'Arriving ${analysis.request.destination.name}'
            : (place != null && place.isNotEmpty ? 'Near $place' : 'En route');
    final up = frame.sun.isUp;
    final strength = ExposureModel.altitudeFactor(frame.sun.altitude) * (frame.weather?.sunlightFactor ?? 1);
    final sideColor = ColorUtils.sunSideColor(frame.sunSide, strength * 1.4);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(TimeUtils.time(frame.time), style: AppTextStyles.metric.copyWith(fontSize: 24, height: 1.05)),
              const SizedBox(height: 3),
              Text(
                '$where · ${TimeUtils.distanceKm(frame.distanceKm)} · ${frame.speedKmh.round()} km/h',
                style: AppTextStyles.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: (up ? sideColor : AppColors.accentShade).withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (up ? sideColor : AppColors.accentShade).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              WeatherIcon(
                condition: frame.weather?.condition,
                night: !up,
                size: 16,
                animate: false,
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    up ? 'Sun ${frame.sunSide.label.toLowerCase()}' : 'Sun down',
                    style: AppTextStyles.caption.copyWith(
                      color: up ? sideColor : AppColors.accentShade,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    frame.weather != null
                        ? '${frame.weather!.temperature.round()}° · ${frame.weather!.condition.label}'
                        : (up ? '${frame.sun.altitude.round()}° high' : 'No direct sun'),
                    style: AppTextStyles.caption.copyWith(fontSize: 10.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Timeline extends ConsumerWidget {
  const _Timeline({required this.analysis, required this.progress});
  final TripAnalysis analysis;
  final double progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        void seekTo(double dx) {
          ref.read(playbackProvider.notifier).seek(dx / constraints.maxWidth);
        }

        return Semantics(
          slider: true,
          label: 'Journey time',
          value: TimeUtils.time(analysis.frameAt(progress).time),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) {
              ref.read(playbackProvider.notifier).pause();
              seekTo(d.localPosition.dx);
            },
            onHorizontalDragStart: (d) {
              HapticFeedback.selectionClick();
              ref.read(playbackProvider.notifier).pause();
              seekTo(d.localPosition.dx);
            },
            onHorizontalDragUpdate: (d) => seekTo(d.localPosition.dx),
            child: SizedBox(
              height: 54,
              width: double.infinity,
              child: CustomPaint(painter: _TimelinePainter(analysis, progress)),
            ),
          ),
        );
      },
    );
  }
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter(this.analysis, this.progress);
  final TripAnalysis analysis;
  final double progress;

  static const _minAlt = -12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final points = analysis.points;
    const barH = 9.0;
    final curve = Rect.fromLTRB(0, 4, size.width, size.height - barH - 6);
    final bar = Rect.fromLTRB(0, size.height - barH, size.width, size.height);
    final maxAlt = math.max(25.0, points.map((p) => p.sun.altitude).reduce(math.max));
    double xOf(int i) => size.width * analysis.progressOfIndex(i);
    double yOf(double alt) =>
        curve.bottom - curve.height * ((alt.clamp(_minAlt, maxAlt) - _minAlt) / (maxAlt - _minAlt));
    final horizonY = yOf(0);

    // Curve background.
    canvas.drawRRect(
      RRect.fromRectAndRadius(curve, const Radius.circular(8)),
      Paint()..color = AppColors.bgPrimary.withValues(alpha: 0.6),
    );

    // Sun altitude area (above the horizon only).
    final line = Path()..moveTo(xOf(0), yOf(points.first.sun.altitude));
    for (var i = 1; i < points.length; i++) {
      line.lineTo(xOf(i), yOf(points[i].sun.altitude));
    }
    final area = Path.from(line)
      ..lineTo(size.width, horizonY)
      ..lineTo(0, horizonY)
      ..close();
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(curve.left, curve.top, curve.right, horizonY));
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.accentSun.withValues(alpha: 0.45), AppColors.accentSun.withValues(alpha: 0.04)],
        ).createShader(curve),
    );
    canvas.restore();
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = AppColors.accentSun.withValues(alpha: 0.9),
    );

    // Horizon.
    final dash = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, horizonY), Offset(math.min(x + 3, size.width), horizonY), dash);
    }

    // Sunrise / sunset markers.
    for (final e in analysis.stats.events) {
      final x = size.width * e.progress;
      final tp = TextPainter(
        text: TextSpan(
          text: e.type == SunEventType.sunrise ? '☀︎↑' : '☀︎↓',
          style: const TextStyle(fontSize: 9, color: AppColors.accentSun, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((x - tp.width / 2).clamp(0, size.width - tp.width), curve.top + 1));
    }

    // Weather bar.
    WeatherBarPainter.paint(canvas, bar, points, radius: 4.5);

    // Dim the part not travelled yet.
    final px = size.width * progress;
    canvas.drawRect(
      Rect.fromLTRB(px, curve.top, size.width, size.height),
      Paint()..color = AppColors.bgSecondary.withValues(alpha: 0.35),
    );

    // Playhead.
    canvas.drawLine(
      Offset(px, curve.top),
      Offset(px, bar.bottom),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );
    final alt = analysis.frameAt(progress).sun.altitude;
    if (alt > _minAlt) {
      canvas.drawCircle(Offset(px, yOf(alt)), 4, Paint()..color = alt > 0 ? AppColors.accentSun : AppColors.textMuted);
    }
    final knob = Offset(px.clamp(8.0, size.width - 8), bar.center.dy);
    canvas.drawCircle(knob, 9.5, Paint()..color = Colors.black.withValues(alpha: 0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawCircle(knob, 8.5, Paint()..color = Colors.white);
    canvas.drawCircle(knob, 4, Paint()..color = AppColors.accentWarm);
  }

  @override
  bool shouldRepaint(_TimelinePainter old) =>
      old.progress != progress || !identical(old.analysis, analysis);
}

class _TickLabels extends StatelessWidget {
  const _TickLabels({required this.analysis});
  final TripAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.caption.copyWith(fontSize: 10.5, color: AppColors.textMuted);
    final d = analysis.duration;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final f in [0.0, 0.25, 0.5, 0.75, 1.0])
          Text(
            TimeUtils.time(analysis.departure.add(d * f)),
            style: style,
          ),
      ],
    );
  }
}
