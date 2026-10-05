import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../results/presentation/providers/results_provider.dart';
import '../../../results/presentation/providers/trip_analysis.dart';
import '../../domain/entities/seat.dart';
import '../../domain/entities/vehicle_layout.dart';
import 'exposure_chart.dart';
import 'score_ring.dart';

/// "Left window · Row 4" style description.
String describeSeat(Seat s, VehicleLayout layout) {
  if (layout.type.isCar) {
    return s.isWindow ? '${s.label} · window' : '${s.label} · no window';
  }
  final pos = s.isMiddle
      ? 'Middle seat'
      : '${s.side == SeatSide.left ? 'Left' : 'Right'} ${s.isWindow ? 'window' : 'aisle'}';
  return '$pos · Row ${s.row}';
}

String seatTitle(Seat s, VehicleLayout layout) =>
    layout.type.isCar ? s.label : 'Seat ${s.id}';

Future<void> showSeatQuickSheet(BuildContext context, String seatId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SeatQuickSheet(seatId: seatId),
  );
}

class _SeatQuickSheet extends ConsumerWidget {
  const _SeatQuickSheet({required this.seatId});
  final String seatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(currentAnalysisProvider);
    if (analysis == null) return const SizedBox.shrink();
    final seat = analysis.layout.seatById(seatId);
    final score = analysis.scoreById[seatId];
    if (seat == null || score == null) return const SizedBox.shrink();
    final progress = ref.watch(playbackProvider.select((s) => s.progress));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.borderStrong, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              ScoreRing(score: score.overallScore, size: 68, stroke: 7),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(seatTitle(seat, analysis.layout), style: AppTextStyles.h1),
                    const SizedBox(height: 2),
                    Text(describeSeat(seat, analysis.layout), style: AppTextStyles.caption),
                    const SizedBox(height: 6),
                    RankChip(rank: score.rank, total: analysis.scores.length, label: score.recommendation),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(score.reason, style: AppTextStyles.bodySecondary),
          const SizedBox(height: 14),
          SeatStatsRow(analysis: analysis, seatId: seatId),
          const SizedBox(height: 16),
          ExposureChart(
            points: analysis.points,
            series: analysis.exposure[seatId]!,
            progress: progress,
            height: 120,
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/seat/$seatId');
            },
            icon: const Icon(Icons.insights_rounded, size: 18),
            label: const Text('Full breakdown'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.bgCard,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

class RankChip extends StatelessWidget {
  const RankChip({super.key, required this.rank, required this.total, this.label = ''});
  final int rank;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    final avoid = label == 'Avoid';
    final color = avoid ? AppColors.accentHot : (label.isNotEmpty ? AppColors.gold : AppColors.textSecondary);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _chip('#$rank of $total', AppColors.textSecondary),
        if (label.isNotEmpty) _chip(label, color),
      ],
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(text, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
      );
}

/// Four compact stats for a seat.
class SeatStatsRow extends StatelessWidget {
  const SeatStatsRow({super.key, required this.analysis, required this.seatId});
  final TripAnalysis analysis;
  final String seatId;

  @override
  Widget build(BuildContext context) {
    final s = analysis.scoreById[seatId]!;
    final cloudCut = s.rawExposure > 0 ? (1 - s.weatherAdjustedExposure / s.rawExposure) * 100 : 0.0;
    final items = [
      ('Direct sun', '${s.totalSunExposureMinutes.round()} min', Icons.wb_sunny_outlined),
      ('Peak', '${(s.peakExposureIntensity * 100).round()}%', Icons.trending_up_rounded),
      ('Airflow', '${(s.ventilationScore * 100).round()}%', Icons.air_rounded),
      ('Clouds cut', '${cloudCut.round()}%', Icons.cloud_outlined),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Icon(items[i].$3, size: 16, color: AppColors.textSecondary),
                  const SizedBox(height: 4),
                  FittedBox(child: Text(items[i].$2, style: AppTextStyles.metricSmall)),
                  Text(items[i].$1, style: AppTextStyles.caption.copyWith(fontSize: 10.5), maxLines: 1),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
