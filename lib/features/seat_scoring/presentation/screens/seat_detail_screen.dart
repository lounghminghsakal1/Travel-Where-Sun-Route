import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../results/presentation/providers/results_provider.dart';
import '../widgets/exposure_chart.dart';
import '../widgets/score_ring.dart';
import '../widgets/seat_map_widget.dart';
import '../widgets/seat_quick_sheet.dart';

class SeatDetailScreen extends ConsumerWidget {
  const SeatDetailScreen({super.key, required this.seatId});
  final String seatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(currentAnalysisProvider);
    final seat = analysis?.layout.seatById(seatId);
    final score = analysis?.scoreById[seatId];

    if (analysis == null || seat == null || score == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Seat not found', style: AppTextStyles.h2),
              const SizedBox(height: 12),
              TextButton(onPressed: () => context.go('/'), child: const Text('Plan a trip')),
            ],
          ),
        ),
      );
    }

    final progress = ref.watch(playbackProvider.select((s) => s.progress));
    final frame = ref.watch(journeyFrameProvider);
    final live = frame?.seatExposure[seatId] ?? 0;

    final breakdown = [
      ('Sun protection', score.sunProtectionScore, '65%', Icons.shield_moon_outlined),
      ('Ventilation', score.ventilationScore * 100, '20%', Icons.air_rounded),
      ('Comfort', score.comfortScore * 10, '15%', Icons.event_seat_outlined),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(seatTitle(seat, analysis.layout)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/results'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    ScoreRing(score: score.overallScore, size: 104),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(describeSeat(seat, analysis.layout), style: AppTextStyles.title),
                          const SizedBox(height: 8),
                          RankChip(rank: score.rank, total: analysis.scores.length, label: score.recommendation),
                          const SizedBox(height: 10),
                          Text(score.reason, style: AppTextStyles.bodySecondary.copyWith(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Score breakdown', subtitle: 'Weighted into the overall score'),
              GlassCard(
                child: Column(
                  children: [
                    for (var i = 0; i < breakdown.length; i++) ...[
                      if (i > 0) const SizedBox(height: 14),
                      _BreakdownBar(
                        label: breakdown[i].$1,
                        value: breakdown[i].$2,
                        weight: breakdown[i].$3,
                        icon: breakdown[i].$4,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SeatStatsRow(analysis: analysis, seatId: seatId),
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Sun on this seat',
                subtitle: 'Intensity across the journey',
                trailing: _LivePill(value: live),
              ),
              GlassCard(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: ExposureChart(
                  points: analysis.points,
                  series: analysis.exposure[seatId]!,
                  progress: progress,
                  height: 170,
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Where it is'),
              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SeatMapWidget(
                  analysis: analysis,
                  compact: true,
                  focusSeatId: seatId,
                  maxBodyWidth: analysis.layout.type.isCar ? 150 : 170,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreakdownBar extends StatelessWidget {
  const _BreakdownBar({required this.label, required this.value, required this.weight, required this.icon});
  final String label;
  final double value;
  final String weight;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = ColorUtils.scoreColor(value);
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: AppTextStyles.body)),
            Text('weight $weight', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
            const SizedBox(width: 10),
            SizedBox(
              width: 34,
              child: Text(
                value.round().toString(),
                textAlign: TextAlign.right,
                style: AppTextStyles.metricSmall.copyWith(color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value / 100),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 6,
              color: color,
              backgroundColor: AppColors.bgElevated,
            ),
          ),
        ),
      ],
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    final color = ColorUtils.exposureColor(value / 0.8);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Now: ${ColorUtils.exposureLabel(value)}',
        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
