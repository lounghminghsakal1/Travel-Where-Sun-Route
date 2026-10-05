import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pressable.dart';

/// Date and time tiles that open the platform pickers.
class DepartureTimePicker extends StatelessWidget {
  const DepartureTimePicker({super.key, required this.value, required this.onChanged});

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = DateTime(d.year, d.month, d.day).difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return DateFormat('EEEE').format(d);
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value.isBefore(now) ? now : value,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 14)),
      helpText: 'Departure date',
    );
    if (picked != null) {
      onChanged(DateTime(picked.year, picked.month, picked.day, value.hour, value.minute));
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
      helpText: 'Departure time',
    );
    if (picked != null) {
      onChanged(DateTime(value.year, value.month, value.day, picked.hour, picked.minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    final beyondForecast = value.difference(DateTime.now()).inHours > 5 * 24;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Tile(
                icon: Icons.calendar_today_rounded,
                label: _dayLabel(value),
                value: DateFormat('EEE, d MMM').format(value),
                onTap: () => _pickDate(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Tile(
                icon: Icons.schedule_rounded,
                label: 'Departs',
                value: DateFormat.jm().format(value),
                onTap: () => _pickTime(context),
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          child: beyondForecast
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.accentSun),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Beyond the 5-day forecast, so clear skies will be assumed.',
                          style: AppTextStyles.caption.copyWith(color: AppColors.accentSun),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.value, required this.onTap});
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label $value',
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.accentSun.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: AppColors.accentSun),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label.toUpperCase(), style: AppTextStyles.overline.copyWith(fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(value, style: AppTextStyles.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
