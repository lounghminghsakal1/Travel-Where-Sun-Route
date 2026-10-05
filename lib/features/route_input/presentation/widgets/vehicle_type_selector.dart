import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../seat_scoring/domain/entities/vehicle_layout.dart';

IconData vehicleIcon(VehicleType t) => switch (t) {
      VehicleType.bus => Icons.directions_bus_filled_rounded,
      VehicleType.train => Icons.train_rounded,
      VehicleType.car4 => Icons.directions_car_filled_rounded,
      VehicleType.car5plus => Icons.airport_shuttle_rounded,
    };

class VehicleTypeSelector extends StatelessWidget {
  const VehicleTypeSelector({super.key, required this.value, required this.onChanged});

  final VehicleType value;
  final ValueChanged<VehicleType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final t in VehicleType.values) ...[
          if (t != VehicleType.values.first) const SizedBox(width: 10),
          Expanded(
            child: _VehicleCard(
              type: t,
              selected: t == value,
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(t);
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.type, required this.selected, required this.onTap});
  final VehicleType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${type.label}, ${type.subtitle}',
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentSun.withValues(alpha: 0.1) : AppColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.accentSun.withValues(alpha: 0.8) : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [BoxShadow(color: AppColors.accentSun.withValues(alpha: 0.15), blurRadius: 18, offset: const Offset(0, 6))]
                : null,
          ),
          child: Column(
            children: [
              AnimatedScale(
                scale: selected ? 1.08 : 1,
                duration: const Duration(milliseconds: 220),
                child: Icon(
                  vehicleIcon(type),
                  size: 28,
                  color: selected ? AppColors.accentSun : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                type.label,
                style: AppTextStyles.title.copyWith(
                  fontSize: 14,
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${type.capacity} seats',
                style: AppTextStyles.caption.copyWith(fontSize: 11),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
