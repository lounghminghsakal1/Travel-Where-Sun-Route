import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../results/presentation/providers/results_provider.dart';
import '../../../results/presentation/providers/trip_analysis.dart';
import 'weather_icon_widget.dart';

/// Horizontal list of forecast cards at each weather waypoint.
class WeatherWaypointsStrip extends ConsumerWidget {
  const WeatherWaypointsStrip({super.key, required this.analysis});
  final TripAnalysis analysis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(journeyFrameProvider)?.pointIndex ?? 0;
    final waypoints = analysis.waypoints;

    // Which card is "now": the last waypoint already passed.
    var active = 0;
    for (var i = 0; i < waypoints.length; i++) {
      if (waypoints[i].pointIndex <= current) active = i;
    }

    return SizedBox(
      height: 142,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: waypoints.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final w = waypoints[i];
          final night = !analysis.points[w.pointIndex].sun.isUp;
          final isActive = i == active;
          final place = i == 0
              ? analysis.request.origin.name
              : i == waypoints.length - 1
                  ? analysis.request.destination.name
                  : (w.placeName?.isNotEmpty ?? false)
                      ? w.placeName!
                      : '${w.distanceKm.round()} km';
          return Pressable(
            onTap: () => ref.read(playbackProvider.notifier).seek(analysis.progressOfIndex(w.pointIndex)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 104,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive ? AppColors.bgElevated : AppColors.bgCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isActive ? AppColors.accentSun.withValues(alpha: 0.5) : AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(TimeUtils.time(w.eta), style: AppTextStyles.caption.copyWith(fontSize: 11)),
                  const SizedBox(height: 8),
                  WeatherIcon(condition: w.weather?.condition, night: night, size: 26),
                  const Spacer(),
                  Text(
                    w.weather != null ? '${w.weather!.temperature.round()}°' : '—',
                    style: AppTextStyles.metricSmall.copyWith(fontSize: 17),
                  ),
                  Text(
                    w.weather != null
                        ? '${w.weather!.cloudCover}% cloud'
                        : (w.beyondForecast ? 'Beyond forecast' : 'Unavailable'),
                    style: AppTextStyles.caption.copyWith(fontSize: 10.5),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place,
                    style: AppTextStyles.caption.copyWith(fontSize: 10.5, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
