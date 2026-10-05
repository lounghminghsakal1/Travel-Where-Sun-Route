import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/entities/geo_point.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/geo_utils.dart';
import '../../../../seat_scoring/domain/usecases/exposure_model.dart';
import '../../../../weather/domain/entities/weather_data.dart';
import '../../../../weather/presentation/widgets/weather_icon_widget.dart';
import '../../providers/results_provider.dart';
import '../../providers/trip_analysis.dart';
import 'route_map_shared.dart';

extension on GeoPoint {
  LatLng get latLng => LatLng(lat, lng);
}

/// Keyless fallback map (web/desktop): OpenStreetMap tiles darkened to match
/// the app.
class OsmRouteMap extends ConsumerStatefulWidget {
  const OsmRouteMap({
    super.key,
    required this.analysis,
    required this.fitPadding,
    required this.controlsPadding,
  });

  final TripAnalysis analysis;
  final EdgeInsets fitPadding;
  final EdgeInsets controlsPadding;

  @override
  ConsumerState<OsmRouteMap> createState() => _OsmRouteMapState();
}

class _OsmRouteMapState extends ConsumerState<OsmRouteMap> {
  final _controller = MapController();
  bool _ready = false;
  bool _follow = false;
  late LatLngBounds _bounds;
  late List<Polyline> _routeLines;
  late List<Polyline> _casing;

  @override
  void initState() {
    super.initState();
    _buildRoute();
  }

  @override
  void didUpdateWidget(OsmRouteMap old) {
    super.didUpdateWidget(old);
    if (!identical(old.analysis, widget.analysis)) {
      _buildRoute();
      if (_ready) _fit();
    }
  }

  void _buildRoute() {
    final geo = widget.analysis.route.points;
    final all = [for (final p in geo) p.latLng];
    _bounds = LatLngBounds.fromPoints(all);
    _routeLines = [
      for (final s in buildSunSegments(widget.analysis))
        Polyline(points: [for (final p in s.points) p.latLng], color: s.color, strokeWidth: 5),
    ];
    _casing = [Polyline(points: all, color: Colors.black.withValues(alpha: 0.6), strokeWidth: 9)];
  }

  void _fit() => _controller.fitCamera(CameraFit.bounds(bounds: _bounds, padding: widget.fitPadding));

  void _onTap(TapPosition _, LatLng latLng) {
    final threshold = pixelsToKm(32, _controller.camera.zoom, latLng.latitude);
    final index = nearestSampleIndex(widget.analysis, GeoPoint(latLng.latitude, latLng.longitude), threshold);
    if (index == null) return;
    HapticFeedback.selectionClick();
    ref.read(playbackProvider.notifier)
      ..pause()
      ..seek(widget.analysis.progressOfIndex(index));
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.analysis;
    ref.listen<JourneyFrame?>(journeyFrameProvider, (_, frame) {
      if (_follow && _ready && frame != null) {
        _controller.move(frame.location.latLng, math.max(_controller.camera.zoom, 11));
      }
    });

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(bounds: _bounds, padding: widget.fitPadding),
            backgroundColor: const Color(0xFF0E0F13),
            minZoom: 3,
            maxZoom: 18,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onTap: _onTap,
            onMapReady: () => _ready = true,
            onPositionChanged: (_, hasGesture) {
              if (hasGesture && _follow) setState(() => _follow = false);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: ApiConstants.osmTiles,
              userAgentPackageName: AppConstants.packageName,
              tileBuilder: darkModeTileBuilder,
            ),
            PolylineLayer(polylines: _casing),
            PolylineLayer(polylines: _routeLines),
            const _TrailLayer(),
            MarkerLayer(
              markers: [
                for (final w in a.waypoints.skip(1).take(math.max(0, a.waypoints.length - 2)))
                  if (w.weather != null)
                    Marker(
                      point: w.location.latLng,
                      width: 66,
                      height: 30,
                      child: GestureDetector(
                        onTap: () => ref.read(playbackProvider.notifier).seek(a.progressOfIndex(w.pointIndex)),
                        child: _WeatherChip(
                          condition: w.weather!.condition,
                          temperature: w.weather!.temperature,
                          night: !a.points[w.pointIndex].sun.isUp,
                        ),
                      ),
                    ),
                Marker(point: a.route.points.first.latLng, width: 22, height: 22, child: const _OriginDot()),
                Marker(
                  point: a.route.points.last.latLng,
                  width: 36,
                  height: 36,
                  alignment: Alignment.topCenter,
                  child: const Icon(Icons.location_on_rounded, color: AppColors.accentHot, size: 36,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 8)]),
                ),
              ],
            ),
            const _VehicleMarkerLayer(),
          ],
        ),
        // Required OpenStreetMap attribution, kept above the bottom sheet.
        Positioned(
          left: 8,
          bottom: math.max(8, widget.fitPadding.bottom - 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('© OpenStreetMap contributors',
                style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.textSecondary)),
          ),
        ),
        Positioned(
          top: widget.controlsPadding.top,
          right: widget.controlsPadding.right,
          child: MapControls(
            following: _follow,
            onFollow: () {
              setState(() => _follow = !_follow);
              final frame = ref.read(journeyFrameProvider);
              if (_follow && frame != null) {
                _controller.move(frame.location.latLng, math.max(_controller.camera.zoom, 12));
              }
            },
            onFit: () {
              setState(() => _follow = false);
              _fit();
            },
          ),
        ),
      ],
    );
  }
}

class _OriginDot extends StatelessWidget {
  const _OriginDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accentCool,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
      ),
    );
  }
}

class _WeatherChip extends StatelessWidget {
  const _WeatherChip({required this.condition, required this.temperature, required this.night});
  final WeatherCondition condition;
  final double temperature;
  final bool night;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.borderStrong),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          WeatherIcon(condition: condition, night: night, size: 15),
          const SizedBox(width: 4),
          Text('${temperature.round()}°',
              style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Fading trail behind the vehicle.
class _TrailLayer extends ConsumerWidget {
  const _TrailLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(currentAnalysisProvider);
    final frame = ref.watch(journeyFrameProvider);
    if (analysis == null || frame == null || frame.pointIndex == 0) {
      return const PolylineLayer<Object>(polylines: []);
    }
    final from = math.max(0, frame.pointIndex - 18);
    final pts = [
      for (var i = from; i <= frame.pointIndex; i++) analysis.points[i].location.latLng,
      frame.location.latLng,
    ];
    return PolylineLayer(
      polylines: [
        Polyline(
          points: pts,
          strokeWidth: 5,
          gradientColors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.95)],
        ),
      ],
    );
  }
}

class _VehicleMarkerLayer extends ConsumerWidget {
  const _VehicleMarkerLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frame = ref.watch(journeyFrameProvider);
    if (frame == null) return const MarkerLayer(markers: []);
    final strength = ExposureModel.altitudeFactor(frame.sun.altitude) * (frame.weather?.sunlightFactor ?? 1);
    return MarkerLayer(
      markers: [
        Marker(
          point: frame.location.latLng,
          width: 130,
          height: 130,
          child: IgnorePointer(
            child: CustomPaint(
              painter: _PuckPainter(
                bearing: frame.bearing,
                sunAzimuth: frame.sun.azimuth,
                sunUp: frame.sun.isUp,
                strength: strength,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PuckPainter extends CustomPainter {
  _PuckPainter({required this.bearing, required this.sunAzimuth, required this.sunUp, required this.strength});
  final double bearing;
  final double sunAzimuth;
  final bool sunUp;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    if (sunUp) {
      final a = GeoUtils.toRad(sunAzimuth);
      final dir = Offset(math.sin(a), -math.cos(a));
      final alpha = (0.35 + strength * 0.65).clamp(0.0, 1.0);
      final dash = Paint()
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = AppColors.accentSun.withValues(alpha: alpha);
      for (var t = 16.0; t < 50; t += 7) {
        canvas.drawLine(c + dir * t, c + dir * math.min(t + 3.5, 50), dash);
      }
      final end = c + dir * 56;
      canvas.drawCircle(end, 10, Paint()..color = AppColors.accentSun.withValues(alpha: 0.25 * alpha));
      canvas.drawCircle(end, 5.5, Paint()..color = AppColors.accentSun.withValues(alpha: alpha));
    }
    canvas.drawCircle(c, 22, Paint()..color = AppColors.accentSun.withValues(alpha: 0.16));
    canvas.drawCircle(
      c,
      13,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(c, 12, Paint()..color = Colors.white);
    canvas.drawCircle(c, 9.5, Paint()..color = const Color(0xFF1C1F2A));
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(GeoUtils.toRad(bearing));
    final arrow = Path()
      ..moveTo(0, -7)
      ..lineTo(5.5, 5)
      ..lineTo(0, 2.5)
      ..lineTo(-5.5, 5)
      ..close();
    canvas.drawPath(arrow, Paint()..color = AppColors.accentSun);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PuckPainter old) =>
      old.bearing != bearing || old.sunAzimuth != sunAzimuth || old.sunUp != sunUp || old.strength != strength;
}
