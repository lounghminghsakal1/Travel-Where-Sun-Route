import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../injection.dart';
import '../../../route_input/domain/entities/route_info.dart';
import '../../../route_input/domain/entities/trip_request.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../sun_analysis/domain/entities/journey_stats.dart';
import 'trip_analysis.dart';

enum AnalysisStage {
  route('Finding the route'),
  sun('Tracking the sun minute by minute'),
  weather('Checking the forecast along the way'),
  scoring('Scoring every seat');

  const AnalysisStage(this.label);
  final String label;
}

sealed class AnalysisState {
  const AnalysisState();
}

class AnalysisIdle extends AnalysisState {
  const AnalysisIdle();
}

class AnalysisLoading extends AnalysisState {
  const AnalysisLoading(this.request, this.stage);
  final TripRequest request;
  final AnalysisStage stage;
}

class AnalysisSuccess extends AnalysisState {
  const AnalysisSuccess(this.analysis);
  final TripAnalysis analysis;
}

class AnalysisError extends AnalysisState {
  const AnalysisError(this.request, this.failure);
  final TripRequest request;
  final Failure failure;
}

/// Orchestrates route → sun → weather → seat scoring for a trip.
final tripAnalysisProvider =
    NotifierProvider<TripAnalysisNotifier, AnalysisState>(TripAnalysisNotifier.new);

class TripAnalysisNotifier extends Notifier<AnalysisState> {
  int _run = 0;

  @override
  AnalysisState build() => const AnalysisIdle();

  Future<void> run(TripRequest request) async {
    final run = ++_run;
    bool stale() => !ref.mounted || run != _run;

    state = AnalysisLoading(request, AnalysisStage.route);
    final routeResult = await ref.read(getRouteProvider)(request);
    if (stale()) return;
    if (routeResult case Err(:final failure)) {
      state = AnalysisError(request, failure);
      return;
    }
    final route = (routeResult as Ok<RouteInfo>).value;

    state = AnalysisLoading(request, AnalysisStage.sun);
    await _breathe();
    if (stale()) return;
    final sampled = ref.read(computeSunPositionsProvider)(
      route: route,
      departure: request.departure,
      durationFactor: request.vehicle.durationFactor,
    );
    if (sampled.length < 2) {
      state = AnalysisError(request, const NoRouteFailure('The route is too short to analyse.'));
      return;
    }

    state = AnalysisLoading(request, AnalysisStage.weather);
    final weather = await ref.read(getWeatherAlongRouteProvider)(sampled);
    if (stale()) return;

    state = AnalysisLoading(request, AnalysisStage.scoring);
    await _breathe();
    if (stale()) return;
    final points = weather.points;
    final layout = ref.read(seatRepositoryProvider).getLayout(
          request.vehicle,
          ref.read(settingsProvider).driverPosition,
        );
    final stats = JourneyStats.fromPoints(points);
    final scoring = ref.read(computeSeatScoresProvider)(layout, points);
    final recommendations = ref.read(getSeatRecommendationsProvider)(layout, scoring, stats);

    state = AnalysisSuccess(TripAnalysis(
      request: request,
      route: route,
      points: points,
      layout: layout,
      stats: stats,
      scores: recommendations.scores,
      exposure: scoring.exposure,
      preferences: recommendations.preferences,
      avoid: recommendations.avoid,
      waypoints: weather.waypoints,
      weatherAvailable: weather.available,
      beyondForecast: weather.beyondForecast,
      weatherFailure: weather.failure,
    ));
    ref.read(playbackProvider.notifier).reset();
    ref.read(selectedSeatProvider.notifier).select(null);
    ref.read(highlightedSeatsProvider.notifier).set(const {});
  }

  void retry() {
    final s = state;
    final request = switch (s) {
      AnalysisError(:final request) => request,
      AnalysisLoading(:final request) => request,
      AnalysisSuccess(:final analysis) => analysis.request,
      AnalysisIdle() => null,
    };
    if (request != null) run(request);
  }

  /// Lets the progress UI paint between synchronous compute stages.
  Future<void> _breathe() => Future<void>.delayed(const Duration(milliseconds: 220));
}

// ---------------------------------------------------------------- playback

class PlaybackState {
  const PlaybackState({this.progress = 0, this.playing = false, this.speed = 1});
  final double progress;
  final bool playing;
  final double speed;

  PlaybackState copyWith({double? progress, bool? playing, double? speed}) => PlaybackState(
        progress: progress ?? this.progress,
        playing: playing ?? this.playing,
        speed: speed ?? this.speed,
      );
}

final playbackProvider =
    NotifierProvider<PlaybackNotifier, PlaybackState>(PlaybackNotifier.new);

class PlaybackNotifier extends Notifier<PlaybackState> {
  @override
  PlaybackState build() => const PlaybackState();

  void seek(double progress) => state = state.copyWith(progress: progress.clamp(0.0, 1.0));

  void advance(double delta) {
    final next = state.progress + delta;
    state = next >= 1
        ? state.copyWith(progress: 1, playing: false)
        : state.copyWith(progress: next);
  }

  void toggle() {
    if (state.playing) {
      state = state.copyWith(playing: false);
    } else {
      // Restart from the beginning when the end was reached.
      state = state.copyWith(playing: true, progress: state.progress >= 1 ? 0 : null);
    }
  }

  void pause() => state = state.copyWith(playing: false);
  void setSpeed(double s) => state = state.copyWith(speed: s);
  void reset() => state = PlaybackState(speed: state.speed);
}

/// Interpolated journey state at the scrubber position.
final journeyFrameProvider = Provider<JourneyFrame?>((ref) {
  final analysis = switch (ref.watch(tripAnalysisProvider)) {
    AnalysisSuccess(:final analysis) => analysis,
    _ => null,
  };
  if (analysis == null) return null;
  final progress = ref.watch(playbackProvider.select((s) => s.progress));
  return analysis.frameAt(progress);
});

/// Convenience accessor for the analysed trip, or null.
final currentAnalysisProvider = Provider<TripAnalysis?>((ref) {
  final s = ref.watch(tripAnalysisProvider);
  return s is AnalysisSuccess ? s.analysis : null;
});

// ---------------------------------------------------------------- selection

final selectedSeatProvider =
    NotifierProvider<SelectedSeatNotifier, String?>(SelectedSeatNotifier.new);

class SelectedSeatNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? id) => state = id;
}

/// Seats outlined on the seat map after tapping a recommendation card.
final highlightedSeatsProvider =
    NotifierProvider<HighlightedSeatsNotifier, Set<String>>(HighlightedSeatsNotifier.new);

class HighlightedSeatsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};
  void set(Set<String> ids) => state = ids;
  void toggle(Set<String> ids) =>
      state = (state.length == ids.length && state.containsAll(ids)) ? const {} : ids;
}
