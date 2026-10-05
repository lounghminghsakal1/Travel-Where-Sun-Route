import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../route_input/domain/entities/trip_request.dart';
import '../providers/results_provider.dart';

/// Step-by-step progress while a trip is analysed.
class AnalysisLoadingView extends StatelessWidget {
  const AnalysisLoadingView({super.key, required this.request, required this.stage});
  final TripRequest request;
  final AnalysisStage stage;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.gradientDusk),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              shrinkWrap: true,
              children: [
                Center(child: const _PulsingSun()),
                const SizedBox(height: 28),
                Text('Analysing your trip', style: AppTextStyles.h1, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(
                  '${request.origin.name} → ${request.destination.name}',
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                for (final s in AnalysisStage.values)
                  _StageRow(
                    label: s.label,
                    state: s.index < stage.index
                        ? _StepState.done
                        : s == stage
                            ? _StepState.active
                            : _StepState.pending,
                  ),
                const SizedBox(height: 28),
                const ShimmerCardList(count: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingSun extends StatelessWidget {
  const _PulsingSun();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.accentSun.withValues(alpha: 0.45), AppColors.accentSun.withValues(alpha: 0)],
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1), duration: 1400.ms, curve: Curves.easeInOut),
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFE08A), AppColors.accentSun, AppColors.accentWarm],
              ),
            ),
          ),
          const Icon(Icons.route_rounded, color: Color(0xFF2A1700), size: 24)
              .animate(onPlay: (c) => c.repeat())
              .rotate(duration: 6.seconds),
        ],
      ),
    );
  }
}

enum _StepState { done, active, pending }

class _StageRow extends StatelessWidget {
  const _StageRow({required this.label, required this.state});
  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final Widget leading = switch (state) {
      _StepState.done => const Icon(Icons.check_circle_rounded, color: AppColors.accentCool, size: 22),
      _StepState.active => const SizedBox(
          width: 22,
          height: 22,
          child: Padding(
            padding: EdgeInsets.all(2),
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      _StepState.pending => const Icon(Icons.radio_button_unchecked_rounded, color: AppColors.textMuted, size: 22),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: KeyedSubtree(key: ValueKey(state), child: leading)),
          const SizedBox(width: 14),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: AppTextStyles.body.copyWith(
                color: state == _StepState.pending ? AppColors.textMuted : AppColors.textPrimary,
                fontWeight: state == _StepState.active ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}
