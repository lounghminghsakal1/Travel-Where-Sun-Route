import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Rounded card. With [frosted] it blurs what's behind it (use over maps).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.frosted = false,
    this.color,
    this.borderColor,
    this.gradient,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool frosted;
  final Color? color;
  final Color? borderColor;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    Widget content = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(padding: padding, child: child),
      ),
    );

    content = DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null
            ? (color ?? (frosted ? AppColors.bgSecondary.withValues(alpha: 0.72) : AppColors.bgCard))
            : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: content,
    );

    if (frosted) {
      content = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: content,
      );
    }
    return ClipRRect(borderRadius: borderRadius, child: content);
  }
}

/// Small frosted circular button for map overlays.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.active = false,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    final button = ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: active
              ? AppColors.accentSun.withValues(alpha: 0.9)
              : AppColors.bgSecondary.withValues(alpha: 0.72),
          shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                icon,
                size: size * 0.46,
                color: active ? const Color(0xFF241800) : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
