import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../seat_scoring/domain/entities/seat_zone.dart';
import '../../../route_input/presentation/widgets/vehicle_type_selector.dart';
import '../../../seat_scoring/presentation/widgets/recommendation_card.dart';
import '../../../seat_scoring/presentation/widgets/seat_map_widget.dart';
import '../../../seat_scoring/presentation/widgets/seat_quick_sheet.dart';
import '../../../sun_analysis/presentation/widgets/sun_direction_overlay.dart';
import '../../../weather/presentation/widgets/weather_waypoints_strip.dart';
import '../providers/results_provider.dart';
import '../providers/trip_analysis.dart';
import '../widgets/analysis_loading_view.dart';
import '../widgets/journey_insights.dart';
import '../widgets/route_map_widget.dart';
import '../widgets/time_scrubber_widget.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(playbackProvider.notifier).pause();
    });
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final analysis = ref.read(currentAnalysisProvider);
    final playback = ref.read(playbackProvider);
    if (analysis == null || !playback.playing) return;
    final seconds = analysis.duration.inSeconds;
    if (seconds <= 0) return;
    ref.read(playbackProvider.notifier).advance(dt * playback.speed * AppConstants.playbackBaseRate / seconds);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(playbackProvider.select((s) => s.playing), (_, playing) {
      if (playing && !_ticker.isActive) {
        _last = Duration.zero;
        _ticker.start();
      } else if (!playing && _ticker.isActive) {
        _ticker.stop();
      }
    });

    final state = ref.watch(tripAnalysisProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: switch (state) {
          AnalysisIdle() => const _EmptyState(),
          AnalysisLoading(:final request, :final stage) =>
            AnalysisLoadingView(request: request, stage: stage),
          AnalysisError(:final failure) => SafeArea(
              child: AppErrorView(
                failure: failure,
                onRetry: () => ref.read(tripAnalysisProvider.notifier).retry(),
                secondaryLabel: 'Edit trip',
                onSecondary: () => context.canPop() ? context.pop() : context.go('/'),
              ),
            ),
          AnalysisSuccess(:final analysis) => _ResultsBody(analysis: analysis),
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.route_rounded, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('No trip analysed yet', style: AppTextStyles.h2),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => context.go('/'), child: const Text('Plan a trip')),
        ],
      ),
    );
  }
}

class _ResultsBody extends StatelessWidget {
  const _ResultsBody({required this.analysis});
  final TripAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        if (wide) {
          return Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    RouteMapWidget(
                      analysis: analysis,
                      fitPadding: EdgeInsets.fromLTRB(60, topInset + 110, 60, 60),
                      controlsPadding: EdgeInsets.only(top: topInset + 196, right: 16),
                    ),
                    Positioned(top: 0, left: 0, right: 0, child: _TopBar(analysis: analysis)),
                    Positioned(top: topInset + 76, right: 16, child: const SunDirectionOverlay(size: 84)),
                    Positioned(left: 16, bottom: 16, child: const RouteLegend()),
                  ],
                ),
              ),
              Container(
                width: 450,
                decoration: const BoxDecoration(
                  color: AppColors.bgSecondary,
                  border: Border(left: BorderSide(color: AppColors.border)),
                ),
                child: SafeArea(child: _Panel(analysis: analysis)),
              ),
            ],
          );
        }

        final sheetInitial = 0.5;
        return Stack(
          children: [
            RouteMapWidget(
              analysis: analysis,
              fitPadding: EdgeInsets.fromLTRB(36, topInset + 110, 36, constraints.maxHeight * sheetInitial + 24),
              controlsPadding: EdgeInsets.only(top: topInset + 196, right: 12),
            ),
            Positioned(top: 0, left: 0, right: 0, child: _TopBar(analysis: analysis)),
            Positioned(top: topInset + 70, right: 12, child: const SunDirectionOverlay(size: 84)),
            Positioned(
              top: topInset + 70,
              left: 12,
              right: 110,
              child: const Align(alignment: Alignment.topLeft, child: RouteLegend()),
            ),
            DraggableScrollableSheet(
              initialChildSize: sheetInitial,
              minChildSize: 0.3,
              maxChildSize: 0.94,
              snap: true,
              snapSizes: const [0.5],
              builder: (context, controller) => DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, -6))],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  child: _Panel(analysis: analysis, controller: controller, isSheet: true),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.analysis});
  final TripAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final r = analysis.request;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(
          children: [
            GlassIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back',
              onPressed: () => context.canPop() ? context.pop() : context.go('/'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlassCard(
                frosted: true,
                radius: 22,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${r.origin.name} → ${r.destination.name}',
                      style: AppTextStyles.title.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${r.vehicle.label} · ${TimeUtils.dateTime(r.departure)}',
                      style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            GlassIconButton(
              icon: Icons.ios_share_rounded,
              tooltip: 'Share results',
              onPressed: () => _share(context, analysis),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context, TripAnalysis a) async {
    final r = a.request;
    final buffer = StringBuffer()
      ..writeln('☀️ SunRoute seat advice')
      ..writeln('${r.origin.name} → ${r.destination.name} by ${r.vehicle.label.toLowerCase()}')
      ..writeln('Departs ${TimeUtils.dateTime(r.departure)} · ${TimeUtils.duration(a.duration)} · ${TimeUtils.distanceKm(a.distanceKm)}')
      ..writeln();
    const medals = {ZoneRank.first: '🥇', ZoneRank.second: '🥈', ZoneRank.third: '🥉'};
    for (final z in a.preferences) {
      buffer.writeln('${medals[z.rank]} ${z.title} (${z.area}) — ${z.score.round()}/100');
    }
    if (a.avoid != null) {
      buffer.writeln('⚠️ Avoid ${a.avoid!.title} (${a.avoid!.area}) — ${a.avoid!.score.round()}/100');
    }
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(ShareParams(
      text: buffer.toString().trim(),
      subject: 'Best seats: ${r.origin.name} → ${r.destination.name}',
      sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    ));
  }
}

class _Panel extends ConsumerWidget {
  const _Panel({required this.analysis, this.controller, this.isSheet = false});
  final TripAnalysis analysis;
  final ScrollController? controller;
  final bool isSheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlighted = ref.watch(highlightedSeatsProvider);

    final sections = <Widget>[
      ..._banners(analysis),
      SectionHeader(title: 'Best seats', subtitle: analysis.layout.name),
      for (var i = 0; i < analysis.preferences.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _zoneCard(ref, analysis.preferences[i], highlighted)
              .animate(delay: (80 * i).ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.08, curve: Curves.easeOutCubic),
        ),
      if (analysis.avoid != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _zoneCard(ref, analysis.avoid!, highlighted)
              .animate(delay: 260.ms)
              .fadeIn(duration: 350.ms),
        ),
      const SizedBox(height: 18),
      const SectionHeader(title: 'Live sun view', subtitle: 'Scrub the timeline to watch the light move'),
      GlassCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: SeatMapWidget(
          analysis: analysis,
          onSeatTap: (id) {
            ref.read(selectedSeatProvider.notifier).select(id);
            showSeatQuickSheet(context, id);
          },
        ),
      ),
      const SizedBox(height: 28),
      SectionHeader(
        title: 'Weather along the route',
        subtitle: analysis.weatherAvailable
            ? 'Forecast at each stretch, at the time you pass it'
            : 'Forecast unavailable — assuming clear skies',
      ),
      WeatherWaypointsStrip(analysis: analysis),
      const SizedBox(height: 28),
      const SectionHeader(title: 'Journey insights'),
      JourneyInsights(analysis: analysis),
      const SizedBox(height: 20),
      Text(
        'Route: ${analysis.route.provider} · Weather: OpenWeather · '
        'Sun position computed on device. Road time scaled for ${analysis.request.vehicle.label.toLowerCase()} travel.',
        style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
        textAlign: TextAlign.center,
      ),
    ];

    return CustomScrollView(
      controller: controller,
      slivers: [
        if (isSheet)
          SliverToBoxAdapter(
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.borderStrong, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
        SliverToBoxAdapter(child: _TripHeader(analysis: analysis)),
        SliverPersistentHeader(pinned: true, delegate: _ScrubberHeader(analysis)),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + MediaQuery.of(context).padding.bottom),
          sliver: SliverList.list(children: sections),
        ),
      ],
    );
  }

  Widget _zoneCard(WidgetRef ref, SeatZone zone, Set<String> highlighted) {
    final ids = zone.seatIds.toSet();
    final isOn = highlighted.length == ids.length && highlighted.containsAll(ids);
    return RecommendationCard(
      zone: zone,
      highlighted: isOn,
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(highlightedSeatsProvider.notifier).toggle(ids);
      },
    );
  }

  List<Widget> _banners(TripAnalysis a) {
    final items = <(IconData, Color, String)>[
      if (a.stats.isNight)
        (Icons.nights_stay_rounded, AppColors.accentRain,
            'Night journey: the sun stays below the horizon, so seats are ranked on ventilation and comfort.'),
      if (a.beyondForecast)
        (Icons.event_busy_rounded, AppColors.accentSun,
            'Part of this trip is beyond the 5-day forecast. Clear skies are assumed there (worst case).'),
      if (!a.weatherAvailable)
        (Icons.cloud_off_rounded, AppColors.textSecondary,
            'Weather unavailable${a.weatherFailure != null ? ' (${a.weatherFailure!.message})' : ''}. Clear skies are assumed.'),
      if (a.duration.inHours >= 12)
        (Icons.schedule_rounded, AppColors.textSecondary,
            'Long trip: forecasts get less precise further ahead.'),
    ];
    return [
      for (final (icon, color, text) in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 10),
                Expanded(child: Text(text, style: AppTextStyles.bodySecondary.copyWith(fontSize: 13, color: AppColors.textPrimary))),
              ],
            ),
          ),
        ),
      if (items.isNotEmpty) const SizedBox(height: 6),
    ];
  }
}

class _TripHeader extends StatelessWidget {
  const _TripHeader({required this.analysis});
  final TripAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final r = analysis.request;
    final chips = [
      (Icons.route_rounded, TimeUtils.distanceKm(analysis.distanceKm)),
      (Icons.schedule_rounded, TimeUtils.duration(analysis.duration)),
      (vehicleIcon(r.vehicle), r.vehicle.label),
      (Icons.flag_rounded, 'Arrive ${TimeUtils.time(analysis.arrival)}'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${r.origin.name}  →  ${r.destination.name}',
            style: AppTextStyles.h2,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (icon, label) in chips)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}


class _ScrubberHeader extends SliverPersistentHeaderDelegate {
  _ScrubberHeader(this.analysis);
  final TripAnalysis analysis;

  static const _height = kScrubberPanelHeight + 26;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(
          bottom: BorderSide(color: overlapsContent || shrinkOffset > 0 ? AppColors.border : Colors.transparent),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: TimeScrubberPanel(analysis: analysis),
    );
  }

  @override
  bool shouldRebuild(_ScrubberHeader old) => !identical(old.analysis, analysis);
}
