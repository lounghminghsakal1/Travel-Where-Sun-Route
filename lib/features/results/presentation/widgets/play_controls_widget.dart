import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pressable.dart';
import '../providers/results_provider.dart';
import '../providers/trip_analysis.dart';

/// Rewind / play / forward and speed selection.
class PlayControlsWidget extends ConsumerWidget {
  const PlayControlsWidget({super.key, required this.analysis});
  final TripAnalysis analysis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackProvider);
    final notifier = ref.read(playbackProvider.notifier);
    final step = analysis.duration.inSeconds > 0 ? 600 / analysis.duration.inSeconds : 0.1;

    return Row(
      children: [
        _RoundIcon(
          icon: Icons.replay_10_rounded,
          tooltip: 'Back 10 minutes',
          onTap: () => notifier.seek(playback.progress - step),
        ),
        const SizedBox(width: 6),
        Pressable(
          onTap: () {
            HapticFeedback.lightImpact();
            notifier.toggle();
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.gradientSunButton,
              boxShadow: [
                BoxShadow(color: AppColors.accentWarm.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5)),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
              child: Icon(
                playback.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                key: ValueKey(playback.playing),
                color: const Color(0xFF2A1700),
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _RoundIcon(
          icon: Icons.forward_10_rounded,
          tooltip: 'Forward 10 minutes',
          onTap: () => notifier.seek(playback.progress + step),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.bgPrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final s in AppConstants.playbackSpeeds)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    notifier.setSpeed(s);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      color: playback.speed == s ? AppColors.bgElevated : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '${s.toInt()}×',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: playback.speed == s ? AppColors.accentSun : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap, required this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: 24),
      color: AppColors.textPrimary,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.bgCard,
        fixedSize: const Size(40, 40),
        minimumSize: const Size(40, 40),
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }
}
