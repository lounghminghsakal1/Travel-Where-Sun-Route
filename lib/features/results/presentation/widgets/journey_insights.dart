import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../sun_analysis/domain/entities/journey_stats.dart';
import '../providers/trip_analysis.dart';

/// Where the sun comes from over the trip, plus daylight/cloud stats.
class JourneyInsights extends StatelessWidget {
  const JourneyInsights({super.key, required this.analysis});
  final TripAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final s = analysis.stats;
    final segments = [
      (s.leftShare, AppColors.accentSun, 'Left'),
      (s.frontRearShare, const Color(0xFFFFE08A), 'Ahead/behind'),
      (s.overheadShare, const Color(0xFFB58CFF), 'Overhead'),
      (s.rightShare, AppColors.accentHot, 'Right'),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where the sun comes from', style: AppTextStyles.title),
          const SizedBox(height: 12),
          if (s.isNight)
            Text('The sun is below the horizon for the whole trip.', style: AppTextStyles.bodySecondary)
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    for (final (share, color, _) in segments)
                      if (share > 0.005)
                        Expanded(
                          flex: (share * 1000).round(),
                          child: Container(color: color),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                for (final (share, color, label) in segments)
                  if (share > 0.005)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('$label ${(share * 100).round()}%', style: AppTextStyles.caption),
                      ],
                    ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(
                icon: Icons.wb_twilight_rounded,
                value: TimeUtils.duration(Duration(minutes: s.daylightMinutes.round())),
                label: 'in daylight',
              ),
              _Stat(
                icon: Icons.cloud_outlined,
                value: '${s.avgCloudCover.round()}%',
                label: 'avg cloud',
              ),
              _Stat(
                icon: Icons.filter_drama_outlined,
                value: '${(s.cloudReduction * 100).round()}%',
                label: 'sun blocked',
              ),
            ],
          ),
          for (final e in s.events) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  e.type == SunEventType.sunrise ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
                  size: 16,
                  color: AppColors.accentSun,
                ),
                const SizedBox(width: 8),
                Text(
                  '${e.type == SunEventType.sunrise ? 'Sunrise' : 'Sunset'} en route at ${TimeUtils.time(e.time)}',
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTextStyles.metricSmall),
                Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
