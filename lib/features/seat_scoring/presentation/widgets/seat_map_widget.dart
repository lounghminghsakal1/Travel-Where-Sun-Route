import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../results/presentation/providers/results_provider.dart';
import '../../../results/presentation/providers/trip_analysis.dart';
import '../../../seat_scoring/domain/usecases/exposure_model.dart';
import '../../domain/entities/seat_zone.dart';
import '../../domain/entities/vehicle_layout.dart';
import 'vehicle_painter.dart';

/// Interactive top-down seat map with live sun projection.
class SeatMapWidget extends ConsumerStatefulWidget {
  const SeatMapWidget({
    super.key,
    required this.analysis,
    this.onSeatTap,
    this.compact = false,
    this.focusSeatId,
    this.maxBodyWidth,
  });

  final TripAnalysis analysis;
  final ValueChanged<String>? onSeatTap;

  /// Hides the header and legend (used for small previews).
  final bool compact;

  /// Seat to outline regardless of global selection.
  final String? focusSeatId;
  final double? maxBodyWidth;

  @override
  ConsumerState<SeatMapWidget> createState() => _SeatMapWidgetState();
}

class _SeatMapWidgetState extends ConsumerState<SeatMapWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  SeatColorMode _mode = SeatColorMode.live;

  // Smoothed values so colours and the sun glide rather than jump.
  final Map<String, double> _shown = {};
  Map<String, double> _target = const {};
  double? _angle;
  double _targetAngle = 0;
  double _altitude = 0;
  double _targetAltitude = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
      ..addListener(_smooth)
      ..repeat(reverse: true);
  }

  void _smooth() {
    const k = 0.22;
    _target.forEach((id, v) {
      final cur = _shown[id] ?? v;
      _shown[id] = cur + (v - cur) * k;
    });
    _angle = _angle == null ? _targetAngle : GeoUtils.lerpAngle(_angle!, _targetAngle, k);
    _altitude += (_targetAltitude - _altitude) * k;
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  double get _defaultBodyWidth => switch (widget.analysis.layout.type) {
        VehicleType.bus => 236,
        VehicleType.train => 226,
        VehicleType.car4 => 190,
        VehicleType.car5plus => 200,
      };

  @override
  Widget build(BuildContext context) {
    final analysis = widget.analysis;
    final frame = ref.watch(journeyFrameProvider);
    final selected = widget.focusSeatId ?? ref.watch(selectedSeatProvider);
    final highlighted = widget.compact ? const <String>{} : ref.watch(highlightedSeatsProvider);

    if (frame != null) {
      _target = frame.seatExposure;
      _targetAngle = frame.sunRelativeAngle;
      _targetAltitude = frame.sun.altitude;
      if (_shown.isEmpty) {
        _shown.addAll(_target);
        _altitude = _targetAltitude;
      }
    }

    final scores = {for (final s in analysis.scores) s.seatId: s.overallScore};
    final medals = <String, int>{};
    for (final zone in analysis.preferences) {
      final best = zone.seatIds.reduce(
        (a, b) => (scores[a] ?? 0) >= (scores[b] ?? 0) ? a : b,
      );
      medals[best] = ZoneRank.values.indexOf(zone.rank) + 1;
    }

    final map = LayoutBuilder(
      builder: (context, constraints) {
        final maxBody = widget.maxBodyWidth ?? _defaultBodyWidth;
        final bodyWidth = math.max(
          120.0,
          math.min(maxBody, constraints.maxWidth - VehicleGeometry.margin * 2),
        );
        final size = VehicleGeometry.canvasSize(analysis.layout, bodyWidth);
        final geometry = VehicleGeometry.compute(analysis.layout, size);

        return Center(
          child: GestureDetector(
            onTapUp: widget.onSeatTap == null
                ? null
                : (d) {
                    final id = geometry.seatAt(d.localPosition);
                    final seat = id == null ? null : analysis.layout.seatById(id);
                    if (seat != null && !seat.isDriver) {
                      HapticFeedback.selectionClick();
                      widget.onSeatTap!(id!);
                    }
                  },
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final altitude = _altitude;
                final weatherFactor = frame?.weather?.sunlightFactor ?? 1.0;
                return CustomPaint(
                  size: size,
                  painter: VehiclePainter(
                    geometry: geometry,
                    exposure: _shown,
                    scores: scores,
                    mode: _mode,
                    relativeAngle: _angle ?? _targetAngle,
                    altitude: altitude,
                    sunStrength: (ExposureModel.altitudeFactor(altitude) * 1.4).clamp(0.0, 1.0) * weatherFactor,
                    pulse: Curves.easeInOut.transform(_pulse.value),
                    selectedId: selected,
                    highlighted: highlighted,
                    medals: widget.compact ? const {} : medals,
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (widget.compact) return map;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _SunCaption(frame: frame)),
            const SizedBox(width: 8),
            _ModeToggle(
              mode: _mode,
              onChanged: (m) => setState(() => _mode = m),
            ),
          ],
        ),
        const SizedBox(height: 4),
        map,
        const SizedBox(height: 8),
        _Legend(mode: _mode),
      ],
    );
  }
}

class _SunCaption extends StatelessWidget {
  const _SunCaption({required this.frame});
  final JourneyFrame? frame;

  @override
  Widget build(BuildContext context) {
    final f = frame;
    if (f == null) return const SizedBox.shrink();
    final up = f.sun.isUp;
    final title = !up
        ? 'Sun below the horizon'
        : f.sun.altitude > 65
            ? 'Sun almost overhead'
            : 'Sun at ${f.clockPosition}';
    final sub = !up
        ? 'No direct sunlight right now'
        : '${f.sunSide.label} · ${f.sun.altitude.round()}° above horizon'
            '${f.weather != null && f.weather!.cloudCover > 40 ? ' · ${f.weather!.cloudCover}% cloud' : ''}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.title),
        const SizedBox(height: 2),
        Text(sub, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});
  final SeatColorMode mode;
  final ValueChanged<SeatColorMode> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget item(SeatColorMode m, String label) {
      final active = m == mode;
      return GestureDetector(
        onTap: () => onChanged(m),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: active ? AppColors.bgElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          item(SeatColorMode.live, 'Live'),
          item(SeatColorMode.score, 'Trip score'),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.mode});
  final SeatColorMode mode;

  @override
  Widget build(BuildContext context) {
    final items = mode == SeatColorMode.live
        ? [
            (ColorUtils.exposureColor(0), 'Shade'),
            (ColorUtils.exposureColor(0.45), 'Partial sun'),
            (ColorUtils.exposureColor(1), 'Direct sun'),
          ]
        : [
            (ColorUtils.scoreColor(90), 'Great'),
            (ColorUtils.scoreColor(62), 'Okay'),
            (ColorUtils.scoreColor(35), 'Poor'),
          ];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 6,
      children: [
        for (final (color, label) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.caption),
            ],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.touch_app_rounded, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text('Tap a seat', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          ],
        ),
      ],
    );
  }
}
