import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/sun_button.dart';
import '../../../../core/utils/sun_utils.dart';
import '../../../results/presentation/providers/results_provider.dart';
import '../../data/datasources/route_history_local_data_source.dart';
import '../providers/route_input_provider.dart';
import '../widgets/date_time_picker.dart';
import '../widgets/place_search_field.dart';
import '../widgets/vehicle_type_selector.dart';

class RouteInputScreen extends ConsumerWidget {
  const RouteInputScreen({super.key});

  void _snack(BuildContext context, String text, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), action: action));
  }

  void _submit(BuildContext context, WidgetRef ref) {
    ref.read(routeFormProvider.notifier).refreshDefaultDeparture();
    final form = ref.read(routeFormProvider);
    if (form.origin == null) return _snack(context, 'Choose where you\'re starting from.');
    if (form.destination == null) return _snack(context, 'Choose where you\'re heading.');
    if (form.origin!.location == form.destination!.location) {
      return _snack(context, 'Pick two different places.');
    }
    if (form.departure.isBefore(DateTime.now().subtract(const Duration(minutes: 15)))) {
      return _snack(
        context,
        'That departure time has already passed.',
        action: SnackBarAction(
          label: 'Use soon',
          onPressed: () => ref.read(routeFormProvider.notifier).setDeparture(RouteFormNotifier.defaultDeparture()),
        ),
      );
    }

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final request = form.toRequest()!;
    ref.read(recentTripsProvider.notifier).add(RecentTrip(request.origin, request.destination, request.vehicle));
    ref.read(tripAnalysisProvider.notifier).run(request);
    context.push('/results');
  }

  Future<void> _pick(BuildContext context, WidgetRef ref, {required bool origin}) async {
    final place = await showPlaceSearch(context, title: origin ? 'Starting from' : 'Going to');
    if (place == null) return;
    final notifier = ref.read(routeFormProvider.notifier);
    origin ? notifier.setOrigin(place) : notifier.setDestination(place);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(routeFormProvider);
    final notifier = ref.read(routeFormProvider.notifier);
    final recents = ref.watch(recentTripsProvider);

    final content = <Widget>[
      _BrandBar(onSettings: () => context.push('/settings')),
      const SizedBox(height: 26),
      Text('Sit on the\nshady side.', style: AppTextStyles.display),
      const SizedBox(height: 10),
      Text(
        'We trace the sun along your route, minute by minute, and tell you exactly where to sit.',
        style: AppTextStyles.bodySecondary.copyWith(fontSize: 14.5),
      ),
      const SizedBox(height: 26),
      _RouteCard(
        form: form,
        onPickOrigin: () => _pick(context, ref, origin: true),
        onPickDestination: () => _pick(context, ref, origin: false),
        onSwap: () {
          HapticFeedback.selectionClick();
          notifier.swap();
        },
      ),
      const SizedBox(height: 12),
      DepartureTimePicker(value: form.departure, onChanged: notifier.setDeparture),
      const SizedBox(height: 26),
      const SectionHeader(title: 'Vehicle'),
      VehicleTypeSelector(value: form.vehicle, onChanged: notifier.setVehicle),
      const SizedBox(height: 28),
      SunButton(
        label: 'Find Best Seat',
        icon: Icons.wb_sunny_rounded,
        onPressed: () => _submit(context, ref),
      ),
      const SizedBox(height: 34),
      if (recents.isNotEmpty) ...[
        SectionHeader(
          title: 'Recent trips',
          trailing: TextButton(
            onPressed: () => ref.read(recentTripsProvider.notifier).clear(),
            child: const Text('Clear'),
          ),
        ),
        for (final t in recents.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TripTile(trip: t, onTap: () => notifier.applyTrip(t)),
          ),
        const SizedBox(height: 18),
      ],
      const SectionHeader(title: 'Try a sample trip', subtitle: 'One tap fills the form'),
      SizedBox(
        height: 46,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: sampleTrips.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final t = sampleTrips[i];
            return ActionChip(
              avatar: Icon(vehicleIcon(t.vehicle), size: 17, color: AppColors.accentSun),
              label: Text('${t.origin.name} → ${t.destination.name}'),
              labelStyle: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
              backgroundColor: AppColors.bgCard,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onPressed: () {
                HapticFeedback.selectionClick();
                notifier.applyTrip(t);
              },
            );
          },
        ),
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: _SkyBackground(departure: form.departure)),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
                    children: [
                      for (var i = 0; i < content.length; i++)
                        content[i]
                            .animate(delay: (40 * math.min(i, 10)).ms)
                            .fadeIn(duration: 380.ms)
                            .slideY(begin: 0.06, curve: Curves.easeOutCubic),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandBar extends StatelessWidget {
  const _BrandBar({required this.onSettings});
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: AppColors.gradientSunButton,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: AppColors.accentWarm.withValues(alpha: 0.35), blurRadius: 14)],
          ),
          child: const Icon(Icons.wb_sunny_rounded, size: 21, color: Color(0xFF2A1700)),
        ),
        const SizedBox(width: 10),
        Text('SunRoute', style: AppTextStyles.h2.copyWith(fontSize: 21, fontWeight: FontWeight.w700)),
        const Spacer(),
        GlassIconButton(icon: Icons.tune_rounded, tooltip: 'Settings', onPressed: onSettings),
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.form,
    required this.onPickOrigin,
    required this.onPickDestination,
    required this.onSwap,
  });

  final RouteFormState form;
  final VoidCallback onPickOrigin;
  final VoidCallback onPickDestination;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      radius: 22,
      child: Stack(
        children: [
          Column(
            children: [
              PlaceField(
                label: 'From',
                hint: 'Where are you starting?',
                place: form.origin,
                onTap: onPickOrigin,
                leading: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accentCool, width: 3.5),
                  ),
                ),
              ),
              const Divider(indent: 54, height: 1),
              PlaceField(
                label: 'To',
                hint: 'Where to?',
                place: form.destination,
                onTap: onPickDestination,
                leading: const Icon(Icons.location_on_rounded, color: AppColors.accentHot, size: 22),
              ),
            ],
          ),
          // Dotted connector between the two markers.
          Positioned(
            left: 27,
            top: 46,
            bottom: 46,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < 3; i++)
                  Container(width: 2.5, height: 2.5, decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle)),
              ],
            ),
          ),
          Positioned(
            right: 14,
            top: 0,
            bottom: 0,
            child: Center(
              child: Material(
                color: AppColors.bgElevated,
                shape: const CircleBorder(side: BorderSide(color: AppColors.borderStrong)),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onSwap,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.swap_vert_rounded, size: 22, color: AppColors.textPrimary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripTile extends StatelessWidget {
  const _TripTile({required this.trip, required this.onTap});
  final RecentTrip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 18,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.bgElevated, borderRadius: BorderRadius.circular(12)),
            child: Icon(vehicleIcon(trip.vehicle), size: 20, color: AppColors.accentSun),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${trip.origin.name} → ${trip.destination.name}',
                  style: AppTextStyles.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text('${trip.vehicle.label} · ${trip.vehicle.subtitle}', style: AppTextStyles.caption),
              ],
            ),
          ),
          const Icon(Icons.north_east_rounded, size: 18, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

/// Dusk sky with the sun's daily arc; the sun sits where it will be at the
/// chosen departure time.
class _SkyBackground extends StatelessWidget {
  const _SkyBackground({required this.departure});
  final DateTime departure;

  @override
  Widget build(BuildContext context) {
    // Day/night from a reference point on the time zone's central meridian.
    final hours = departure.hour + departure.minute / 60;
    final dayFraction = ((hours - 6) / 12);
    final reference = SunUtils.position(departure, 20, departure.timeZoneOffset.inMinutes / 4);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: dayFraction),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOutCubic,
      builder: (context, f, _) => CustomPaint(
        painter: _SkyPainter(fraction: f, isUp: reference.altitude > -2),
      ),
    );
  }
}

class _SkyPainter extends CustomPainter {
  _SkyPainter({required this.fraction, required this.isUp});
  final double fraction;
  final bool isUp;

  @override
  void paint(Canvas canvas, Size size) {
    final h = math.min(size.height * 0.55, 460.0);
    final skyRect = Rect.fromLTWH(0, 0, size.width, h);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.bgPrimary,
    );
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isUp
              ? const [Color(0xFF2B2140), Color(0xFF1C1A2E), AppColors.bgPrimary]
              : const [Color(0xFF111A33), Color(0xFF121626), AppColors.bgPrimary],
        ).createShader(skyRect),
    );

    // Sun path arc.
    final cx = size.width * 0.72;
    final baseY = h * 0.62;
    final rx = math.min(size.width * 0.42, 260.0);
    final ry = h * 0.42;
    final arc = Rect.fromCenter(center: Offset(cx, baseY), width: rx * 2, height: ry * 2);
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.12);
    const segments = 46;
    for (var i = 0; i < segments; i += 2) {
      canvas.drawArc(arc, math.pi + math.pi * i / segments, math.pi / segments, false, dash);
    }

    // Sun (or moon) on the arc.
    final t = fraction.clamp(-0.08, 1.08);
    final angle = math.pi + math.pi * t;
    final pos = Offset(cx + rx * math.cos(angle), baseY + ry * math.sin(angle));
    if (isUp && t >= -0.02 && t <= 1.02) {
      canvas.drawCircle(
        pos,
        90,
        Paint()
          ..shader = RadialGradient(
            colors: [AppColors.accentSun.withValues(alpha: 0.32), AppColors.accentWarm.withValues(alpha: 0.08), Colors.transparent],
            stops: const [0, 0.45, 1],
          ).createShader(Rect.fromCircle(center: pos, radius: 90)),
      );
      canvas.drawCircle(
        pos,
        15,
        Paint()
          ..shader = const RadialGradient(colors: [Color(0xFFFFF1C2), AppColors.accentSun])
              .createShader(Rect.fromCircle(center: pos, radius: 15)),
      );
    } else {
      final moon = Offset(cx + rx * 0.45, baseY - ry * 0.8);
      canvas.drawCircle(moon, 40, Paint()..color = const Color(0xFFC9D4FF).withValues(alpha: 0.06));
      canvas.drawCircle(moon, 11, Paint()..color = const Color(0xFFDDE4FF));
      canvas.drawCircle(moon + const Offset(5, -3), 10, Paint()..color = const Color(0xFF151B33));
    }

    // Horizon.
    canvas.drawLine(
      Offset(0, baseY),
      Offset(size.width, baseY),
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.transparent, Colors.white.withValues(alpha: 0.1), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, baseY, size.width, 1)),
    );
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.fraction != fraction || old.isUp != isUp;
}
