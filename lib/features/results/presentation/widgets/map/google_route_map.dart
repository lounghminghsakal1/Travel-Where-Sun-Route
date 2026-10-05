import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/constants/map_styles.dart';
import '../../../../../core/entities/geo_point.dart';
import '../../../../seat_scoring/domain/usecases/exposure_model.dart';
import '../../providers/results_provider.dart';
import '../../providers/trip_analysis.dart';
import 'map_marker_bitmaps.dart';
import 'route_map_shared.dart';

extension on GeoPoint {
  LatLng get latLng => LatLng(lat, lng);
}

/// Google Maps (Android/iOS) view of the analysed route.
class GoogleRouteMap extends ConsumerStatefulWidget {
  const GoogleRouteMap({
    super.key,
    required this.analysis,
    required this.fitPadding,
    required this.controlsPadding,
  });

  final TripAnalysis analysis;
  final EdgeInsets fitPadding;
  final EdgeInsets controlsPadding;

  @override
  ConsumerState<GoogleRouteMap> createState() => _GoogleRouteMapState();
}

class _GoogleRouteMapState extends ConsumerState<GoogleRouteMap> {
  /// Marker/camera updates cross a platform channel, so playback is
  /// throttled to ~25 updates a second.
  static const _frameInterval = Duration(milliseconds: 40);

  GoogleMapController? _map;
  MapMarkerBitmaps? _icons;
  final Map<int, BitmapDescriptor> _weatherIcons = {};
  double _zoom = 9;
  bool _follow = false;
  late LatLngBounds _bounds;
  late Set<Polyline> _routeLines;

  JourneyFrame? _frame;
  DateTime _lastFrameAt = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _pendingFrame;

  @override
  void initState() {
    super.initState();
    _buildRoute();
    _frame = ref.read(journeyFrameProvider);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_icons == null) _loadIcons(MediaQuery.devicePixelRatioOf(context));
  }

  @override
  void didUpdateWidget(GoogleRouteMap old) {
    super.didUpdateWidget(old);
    if (!identical(old.analysis, widget.analysis)) {
      _buildRoute();
      _weatherIcons.clear();
      _loadWeatherIcons(MediaQuery.devicePixelRatioOf(context));
      _fit();
    }
  }

  @override
  void dispose() {
    _pendingFrame?.cancel();
    _map?.dispose();
    super.dispose();
  }

  Future<void> _loadIcons(double dpr) async {
    final icons = await MapMarkerBitmaps.create(dpr);
    if (!mounted) return;
    setState(() => _icons = icons);
    await _loadWeatherIcons(dpr);
  }

  Future<void> _loadWeatherIcons(double dpr) async {
    final a = widget.analysis;
    for (final w in a.waypoints) {
      final weather = w.weather;
      if (weather == null) continue;
      _weatherIcons[w.pointIndex] = await MapMarkerBitmaps.weatherChip(
        dpr,
        condition: weather.condition,
        temperature: weather.temperature,
        night: !a.points[w.pointIndex].sun.isUp,
      );
    }
    if (mounted) setState(() {});
  }

  void _buildRoute() {
    final geo = widget.analysis.route.points;
    var minLat = geo.first.lat, maxLat = geo.first.lat;
    var minLng = geo.first.lng, maxLng = geo.first.lng;
    for (final p in geo) {
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLng = math.min(minLng, p.lng);
      maxLng = math.max(maxLng, p.lng);
    }
    _bounds = LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));

    final all = [for (final p in geo) p.latLng];
    final segments = buildSunSegments(widget.analysis);
    _routeLines = {
      Polyline(
        polylineId: const PolylineId('casing'),
        points: all,
        color: Colors.black.withValues(alpha: 0.6),
        width: 10,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        zIndex: 1,
      ),
      for (var i = 0; i < segments.length; i++)
        Polyline(
          polylineId: PolylineId('sun_$i'),
          points: [for (final p in segments[i].points) p.latLng],
          color: segments[i].color,
          width: 6,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          zIndex: 2,
        ),
    };
  }

  void _fit() {
    _map?.moveCamera(CameraUpdate.newLatLngBounds(_bounds, 24));
  }

  void _onFrame(JourneyFrame? frame) {
    if (frame == null) return;
    final now = DateTime.now();
    final wait = _frameInterval - now.difference(_lastFrameAt);
    _pendingFrame?.cancel();
    if (wait <= Duration.zero) {
      _applyFrame(frame);
    } else {
      _pendingFrame = Timer(wait, () => _applyFrame(frame));
    }
  }

  void _applyFrame(JourneyFrame frame) {
    if (!mounted) return;
    _lastFrameAt = DateTime.now();
    setState(() => _frame = frame);
    if (_follow) {
      _map?.moveCamera(CameraUpdate.newLatLngZoom(frame.location.latLng, math.max(_zoom, 11)));
    }
  }

  void _onTap(LatLng latLng) {
    final threshold = pixelsToKm(32, _zoom, latLng.latitude);
    final index = nearestSampleIndex(widget.analysis, GeoPoint(latLng.latitude, latLng.longitude), threshold);
    if (index == null) return;
    HapticFeedback.selectionClick();
    ref.read(playbackProvider.notifier)
      ..pause()
      ..seek(widget.analysis.progressOfIndex(index));
  }

  Set<Marker> _markers() {
    final a = widget.analysis;
    final icons = _icons;
    if (icons == null) return const {};
    final frame = _frame;
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('origin'),
        position: a.route.points.first.latLng,
        icon: icons.origin,
        anchor: const Offset(0.5, 0.5),
        zIndexInt: 3,
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: a.route.points.last.latLng,
        icon: icons.destination,
        zIndexInt: 3,
      ),
      for (final w in a.waypoints.skip(1).take(math.max(0, a.waypoints.length - 2)))
        if (_weatherIcons[w.pointIndex] != null)
          Marker(
            markerId: MarkerId('wx_${w.pointIndex}'),
            position: w.location.latLng,
            icon: _weatherIcons[w.pointIndex]!,
            anchor: const Offset(0.5, 0.5),
            zIndexInt: 4,
            consumeTapEvents: true,
            onTap: () => ref.read(playbackProvider.notifier).seek(a.progressOfIndex(w.pointIndex)),
          ),
    };
    if (frame != null) {
      final strength = ExposureModel.altitudeFactor(frame.sun.altitude) * (frame.weather?.sunlightFactor ?? 1);
      markers.addAll([
        Marker(
          markerId: const MarkerId('sun'),
          position: frame.location.latLng,
          icon: icons.sunPointer,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          rotation: frame.sun.azimuth,
          visible: frame.sun.isUp,
          alpha: (0.35 + strength * 0.65).clamp(0.0, 1.0),
          zIndexInt: 5,
        ),
        Marker(
          markerId: const MarkerId('vehicle'),
          position: frame.location.latLng,
          icon: icons.vehicle,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          rotation: frame.bearing,
          zIndexInt: 6,
        ),
      ]);
    }
    return markers;
  }

  Set<Polyline> _polylines() {
    final frame = _frame;
    if (frame == null || frame.pointIndex == 0) return _routeLines;
    final from = math.max(0, frame.pointIndex - 18);
    final trail = [
      for (var i = from; i <= frame.pointIndex; i++) widget.analysis.points[i].location.latLng,
      frame.location.latLng,
    ];
    return {
      ..._routeLines,
      Polyline(
        polylineId: const PolylineId('trail'),
        points: trail,
        color: Colors.white.withValues(alpha: 0.85),
        width: 4,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        zIndex: 3,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<JourneyFrame?>(journeyFrameProvider, (_, f) => _onFrame(f));

    return Stack(
      children: [
        Listener(
          // Any finger on the map hands the camera back to the user.
          onPointerDown: (_) {
            if (_follow) setState(() => _follow = false);
          },
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: _bounds.center, zoom: 8),
            style: kDarkMapStyle,
            padding: widget.fitPadding,
            polylines: _polylines(),
            markers: _markers(),
            onMapCreated: (c) {
              _map = c;
              Future<void>.delayed(const Duration(milliseconds: 250), _fit);
            },
            onCameraMove: (p) => _zoom = p.zoom,
            onTap: _onTap,
            compassEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            buildingsEnabled: false,
            indoorViewEnabled: false,
          ),
        ),
        Positioned(
          top: widget.controlsPadding.top,
          right: widget.controlsPadding.right,
          child: MapControls(
            following: _follow,
            onFollow: () {
              setState(() => _follow = !_follow);
              final f = ref.read(journeyFrameProvider);
              if (_follow && f != null) {
                _map?.animateCamera(CameraUpdate.newLatLngZoom(f.location.latLng, math.max(_zoom, 12)));
              }
            },
            onFit: () {
              setState(() => _follow = false);
              _map?.animateCamera(CameraUpdate.newLatLngBounds(_bounds, 24));
            },
          ),
        ),
      ],
    );
  }
}

extension on LatLngBounds {
  LatLng get center => LatLng(
        (southwest.latitude + northeast.latitude) / 2,
        (southwest.longitude + northeast.longitude) / 2,
      );
}
