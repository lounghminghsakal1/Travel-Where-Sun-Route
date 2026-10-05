import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/entities/geo_point.dart';
import '../../../../../core/utils/color_utils.dart';
import '../../../../../core/utils/geo_utils.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../seat_scoring/domain/usecases/exposure_model.dart';
import '../../providers/trip_analysis.dart';

/// A run of route geometry drawn in one colour.
class RouteSegment {
  const RouteSegment(this.points, this.color);
  final List<GeoPoint> points;
  final Color color;
}

/// Splits the full-resolution route into runs coloured by which side of the
/// vehicle the sun is on at that stretch.
List<RouteSegment> buildSunSegments(TripAnalysis a) {
  final geo = a.route.points;
  final samples = a.points;
  final colors = [
    for (final p in samples)
      ColorUtils.sunSideColor(
        p.sunSide,
        ExposureModel.altitudeFactor(p.sun.altitude) * p.sunlightFactor * 1.4,
      ),
  ];

  final segments = <RouteSegment>[];
  var current = <GeoPoint>[geo.first];
  var color = colors.first;
  var j = 0;
  var cum = 0.0;
  for (var i = 1; i < geo.length; i++) {
    cum += GeoUtils.distanceKm(geo[i - 1], geo[i]);
    while (j < samples.length - 1 && samples[j + 1].distanceFromStartKm <= cum) {
      j++;
    }
    current.add(geo[i]);
    if (colors[j] != color) {
      segments.add(RouteSegment(current, color));
      current = [geo[i]];
      color = colors[j];
    }
  }
  if (current.length > 1) segments.add(RouteSegment(current, color));
  return segments;
}

/// Index of the route sample nearest to [p], if within [maxKm].
int? nearestSampleIndex(TripAnalysis a, GeoPoint p, double maxKm) {
  var best = -1;
  var bestD = double.infinity;
  for (var i = 0; i < a.points.length; i++) {
    final d = GeoUtils.distanceKm(a.points[i].location, p);
    if (d < bestD) {
      bestD = d;
      best = i;
    }
  }
  return best >= 0 && bestD <= maxKm ? best : null;
}

/// Ground distance covered by [pixels] at a Web-Mercator [zoom] and [lat].
double pixelsToKm(double pixels, double zoom, double lat) =>
    pixels * 156543.03392 * math.cos(GeoUtils.toRad(lat)) / math.pow(2, zoom) / 1000;

/// Follow-vehicle and fit-route buttons shown over either map.
class MapControls extends StatelessWidget {
  const MapControls({
    super.key,
    required this.following,
    required this.onFollow,
    required this.onFit,
  });

  final bool following;
  final VoidCallback onFollow;
  final VoidCallback onFit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassIconButton(
          icon: Icons.navigation_rounded,
          tooltip: following ? 'Stop following' : 'Follow vehicle',
          active: following,
          onPressed: onFollow,
        ),
        const SizedBox(height: 10),
        GlassIconButton(
          icon: Icons.zoom_out_map_rounded,
          tooltip: 'Show whole route',
          onPressed: onFit,
        ),
      ],
    );
  }
}
