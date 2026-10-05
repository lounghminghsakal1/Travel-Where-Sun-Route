import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/env.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../providers/trip_analysis.dart';
import 'map/google_route_map.dart';
import 'map/osm_route_map.dart';

/// Google Maps on Android/iOS (key injected at build time from `.env`);
/// OpenStreetMap elsewhere, where the Google SDK isn't available.
bool get useGoogleMaps =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) &&
    Env.googleMapsKey.isNotEmpty;

/// Route map with the sun-coloured route, weather chips and the vehicle.
class RouteMapWidget extends StatelessWidget {
  const RouteMapWidget({
    super.key,
    required this.analysis,
    this.fitPadding = const EdgeInsets.all(48),
    this.controlsPadding = const EdgeInsets.only(top: 120, right: 12),
  });

  final TripAnalysis analysis;

  /// Area kept clear of overlays/sheets when fitting the route.
  final EdgeInsets fitPadding;
  final EdgeInsets controlsPadding;

  @override
  Widget build(BuildContext context) {
    return useGoogleMaps
        ? GoogleRouteMap(analysis: analysis, fitPadding: fitPadding, controlsPadding: controlsPadding)
        : OsmRouteMap(analysis: analysis, fitPadding: fitPadding, controlsPadding: controlsPadding);
  }
}

/// Small map legend for route colours.
class RouteLegend extends StatelessWidget {
  const RouteLegend({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      (AppColors.accentSun, 'Sun left'),
      (AppColors.accentHot, 'Sun right'),
      (Color(0xFFFFE08A), 'Ahead/behind'),
      (AppColors.accentShade, 'Shade'),
    ];
    return GlassCard(
      frosted: true,
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Wrap(
        spacing: 10,
        runSpacing: 4,
        children: [
          for (final (color, label) in items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 4,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 5),
                Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10.5, color: AppColors.textPrimary)),
              ],
            ),
        ],
      ),
    );
  }
}
