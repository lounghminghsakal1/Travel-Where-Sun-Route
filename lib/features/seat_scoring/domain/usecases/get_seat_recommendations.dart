import '../../../sun_analysis/domain/entities/journey_stats.dart';
import '../entities/seat.dart';
import '../entities/seat_score.dart';
import '../entities/seat_zone.dart';
import '../entities/vehicle_layout.dart';
import 'compute_seat_scores.dart';

class SeatRecommendations {
  const SeatRecommendations({
    required this.preferences,
    required this.avoid,
    required this.scores,
  });

  /// Up to three zones, best first.
  final List<SeatZone> preferences;
  final SeatZone? avoid;

  /// Ranked seat scores with recommendation labels and reasons filled in.
  final List<SeatScore> scores;
}

/// Groups adjacent similar seats into zones and explains each choice
/// (plan step 9).
class GetSeatRecommendations {
  const GetSeatRecommendations();

  static const _runTolerance = 5.0;

  SeatRecommendations call(
    VehicleLayout layout,
    SeatScoringResult scoring,
    JourneyStats stats,
  ) {
    final byId = {for (final s in scoring.scores) s.seatId: s};
    final seats = layout.passengerSeats.where((s) => byId.containsKey(s.id)).toList();

    final groups = layout.type.isCar
        ? [for (final s in seats) [s]]
        : _runs(seats, byId);

    final candidates = [
      for (final g in groups) _Candidate(g, _mean(g.map((s) => byId[s.id]!.overallScore))),
    ]..sort((a, b) {
        final c = b.score.compareTo(a.score);
        return c != 0 ? c : b.seats.length.compareTo(a.seats.length);
      });

    final top = candidates.take(3).toList();
    final preferences = <SeatZone>[
      for (var i = 0; i < top.length; i++)
        _zone(layout, top[i], ZoneRank.values[i], byId, stats, isBest: i == 0),
    ];

    SeatZone? avoid;
    if (candidates.length > top.length) {
      final worst = candidates.last;
      if (top.isNotEmpty && worst.score < top.first.score - 12) {
        avoid = _zone(layout, worst, ZoneRank.avoid, byId, stats);
      }
    }

    final labels = <String, ZoneRank>{};
    for (final z in [...preferences, ?avoid]) {
      for (final id in z.seatIds) {
        labels[id] = z.rank;
      }
    }

    final scores = [
      for (final s in scoring.scores)
        s.copyWith(
          recommendation: labels[s.seatId]?.label ?? '',
          reason: _seatReason(layout.seatById(s.seatId)!, s, stats),
        ),
    ];

    return SeatRecommendations(preferences: preferences, avoid: avoid, scores: scores);
  }

  // ---------------------------------------------------------------- grouping

  List<List<Seat>> _runs(List<Seat> seats, Map<String, SeatScore> byId) {
    final byCategory = <String, List<Seat>>{};
    for (final s in seats) {
      byCategory.putIfAbsent(_category(s), () => []).add(s);
    }
    final runs = <List<Seat>>[];
    for (final group in byCategory.values) {
      group.sort((a, b) => a.row.compareTo(b.row));
      var current = <Seat>[];
      for (final seat in group) {
        final score = byId[seat.id]!.overallScore;
        if (current.isNotEmpty) {
          final mean = _mean(current.map((s) => byId[s.id]!.overallScore));
          final gap = seat.row - current.last.row;
          if (gap > 1 || (score - mean).abs() > _runTolerance) {
            runs.add(current);
            current = <Seat>[];
          }
        }
        current.add(seat);
      }
      if (current.isNotEmpty) runs.add(current);
    }
    return runs;
  }

  String _category(Seat s) {
    if (s.isMiddle) return 'middle';
    final side = s.side == SeatSide.left ? 'left' : 'right';
    return '$side-${s.isWindow ? 'window' : 'aisle'}';
  }

  // ---------------------------------------------------------------- labels

  SeatZone _zone(
    VehicleLayout layout,
    _Candidate c,
    ZoneRank rank,
    Map<String, SeatScore> byId,
    JourneyStats stats, {
    bool isBest = false,
  }) {
    final seats = c.seats;
    final shaded = stats.daylightMinutes > 0
        ? _mean(seats.map((s) =>
            1 - (byId[s.id]!.totalSunExposureMinutes / stats.daylightMinutes).clamp(0.0, 1.0)))
        : 1.0;
    return SeatZone(
      rank: rank,
      seatIds: [for (final s in seats) s.id],
      title: _title(layout, seats),
      area: _area(layout, seats),
      score: c.score,
      shadedShare: shaded,
      reason: rank == ZoneRank.avoid
          ? _avoidReason(seats, byId, stats)
          : _preferenceReason(layout, seats, shaded, stats, isBest: isBest),
    );
  }

  String _title(VehicleLayout layout, List<Seat> seats) {
    if (seats.length == 1) {
      return layout.type.isCar ? seats.first.label : 'Seat ${seats.first.id}';
    }
    final sameColumn = seats.every((s) => s.column == seats.first.column);
    if (!sameColumn && seats.length <= 3) {
      return 'Seats ${seats.map((s) => s.id).join(', ')}';
    }
    return 'Seats ${seats.first.id}–${seats.last.id}';
  }

  String _area(VehicleLayout layout, List<Seat> seats) {
    final s = seats.first;
    if (layout.type.isCar) {
      return s.isWindow ? 'Window seat' : 'Middle seat · no window';
    }
    final position = s.isMiddle
        ? 'Middle'
        : '${s.side == SeatSide.left ? 'Left' : 'Right'} ${s.isWindow ? 'window' : 'aisle'}';
    final meanRow = _mean(seats.map((e) => e.row.toDouble()));
    final f = layout.rows <= 1 ? 0.0 : (meanRow - 1) / (layout.rows - 1);
    final section = f < 0.34 ? 'Front' : (f < 0.67 ? 'Middle' : 'Rear');
    return '$position · $section';
  }

  String _preferenceReason(
    VehicleLayout layout,
    List<Seat> seats,
    double shaded,
    JourneyStats stats, {
    required bool isBest,
  }) {
    final s = seats.first;
    final parts = <String>[];
    if (stats.isNight) {
      parts.add('Night journey — no direct sun.');
      parts.add('Ranked on ventilation and comfort.');
    } else {
      final pct = (shaded * 100).round();
      final sideName = s.isMiddle
          ? 'This spot'
          : (s.side == SeatSide.left ? 'Left side' : 'Right side');
      if (pct >= 50) {
        parts.add('$sideName stays shaded for $pct% of the daylight journey.');
      } else {
        parts.add('In direct sun ${100 - pct}% of daylight, but less intense than elsewhere.');
      }
      final dominant = stats.dominantSide;
      final seatSide = s.isMiddle ? null : (s.side == SeatSide.left ? 'left' : 'right');
      if (dominant != null && seatSide != null && dominant != seatSide) {
        parts.add('The sun is mostly on the $dominant.');
      }
      if (isBest && stats.cloudReduction > 0.25) {
        parts.add('Clouds cut sunlight by about ${(stats.cloudReduction * 100).round()}% on this trip.');
      }
    }
    parts.add(_ventilationPhrase(layout, s));
    return parts.join(' ');
  }

  String _avoidReason(List<Seat> seats, Map<String, SeatScore> byId, JourneyStats stats) {
    final sunMinutes = _mean(seats.map((s) => byId[s.id]!.totalSunExposureMinutes));
    final peak = _mean(seats.map((s) => byId[s.id]!.peakExposureIntensity));
    final pct = stats.daylightMinutes > 0
        ? (sunMinutes / stats.daylightMinutes * 100).clamp(0, 100).round()
        : 0;
    return 'Direct sun for $pct% of the daylight journey, peaking at ${(peak * 100).round()}% intensity.';
  }

  String _ventilationPhrase(VehicleLayout layout, Seat s) {
    if (layout.isAirConditioned) return 'AC coach, so airflow is even everywhere.';
    if (s.isMiddle) return 'No window, so airflow is limited.';
    if (s.isWindow) return 'Openable window for fresh air.';
    return 'Less airflow, but away from the glass.';
  }

  String _seatReason(Seat seat, SeatScore score, JourneyStats stats) {
    if (stats.isNight) return 'No direct sun on this night journey.';
    final minutes = score.totalSunExposureMinutes.round();
    if (minutes == 0) return 'Stays out of direct sun for the whole trip.';
    final pct = (score.totalSunExposureMinutes / stats.daylightMinutes * 100).clamp(0, 100).round();
    return 'In direct sun for about $minutes min ($pct% of daylight).';
  }

  static double _mean(Iterable<double> values) {
    var sum = 0.0;
    var n = 0;
    for (final v in values) {
      sum += v;
      n++;
    }
    return n == 0 ? 0 : sum / n;
  }
}

class _Candidate {
  _Candidate(this.seats, this.score);
  final List<Seat> seats;
  final double score;
}
