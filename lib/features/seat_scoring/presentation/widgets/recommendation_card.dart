import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/entities/seat_zone.dart';
import 'score_ring.dart';

/// Ranked seat-zone card (1st/2nd/3rd preference or Avoid).
class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
    super.key,
    required this.zone,
    this.highlighted = false,
    this.onTap,
  });

  final SeatZone zone;
  final bool highlighted;
  final VoidCallback? onTap;

  bool get _avoid => zone.rank == ZoneRank.avoid;

  Color get _accent => switch (zone.rank) {
        ZoneRank.first => AppColors.gold,
        ZoneRank.second => AppColors.silver,
        ZoneRank.third => AppColors.bronze,
        ZoneRank.avoid => AppColors.accentHot,
      };

  @override
  Widget build(BuildContext context) {
    final scoreColor = ColorUtils.scoreColor(zone.score);
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        decoration: BoxDecoration(
          color: _avoid ? AppColors.accentHot.withValues(alpha: 0.07) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlighted
                ? _accent.withValues(alpha: 0.85)
                : (_avoid ? AppColors.accentHot.withValues(alpha: 0.25) : AppColors.border),
            width: highlighted ? 1.6 : 1,
          ),
          gradient: zone.rank == ZoneRank.first && !highlighted
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.gold.withValues(alpha: 0.10), AppColors.bgCard],
                  stops: const [0, 0.55],
                )
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Badge(rank: zone.rank, color: _accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(zone.rank.label.toUpperCase(), style: AppTextStyles.overline.copyWith(color: _accent)),
                  const SizedBox(height: 4),
                  Text(zone.title, style: AppTextStyles.h2.copyWith(fontSize: 18)),
                  const SizedBox(height: 2),
                  Text(zone.area, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary.withValues(alpha: 0.75))),
                  const SizedBox(height: 8),
                  Text(zone.reason, style: AppTextStyles.bodySecondary.copyWith(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CountUpText(
                  value: zone.score,
                  style: AppTextStyles.metric.copyWith(color: scoreColor, fontSize: 26, height: 1),
                ),
                Text('/100', style: AppTextStyles.caption.copyWith(fontSize: 11)),
                const SizedBox(height: 8),
                SizedBox(
                  width: 44,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: zone.score / 100),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 4,
                        color: scoreColor,
                        backgroundColor: AppColors.bgElevated,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.rank, required this.color});
  final ZoneRank rank;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isAvoid = rank == ZoneRank.avoid;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isAvoid
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(color, Colors.white, 0.35)!, color, Color.lerp(color, Colors.black, 0.25)!],
              ),
        color: isAvoid ? AppColors.accentHot.withValues(alpha: 0.15) : null,
        boxShadow: isAvoid
            ? null
            : [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      alignment: Alignment.center,
      child: isAvoid
          ? const Icon(Icons.wb_sunny_rounded, color: AppColors.accentHot, size: 20)
          : Text(
              '${ZoneRank.values.indexOf(rank) + 1}',
              style: AppTextStyles.h2.copyWith(color: const Color(0xFF1A1407), fontWeight: FontWeight.w800),
            ),
    );
  }
}
