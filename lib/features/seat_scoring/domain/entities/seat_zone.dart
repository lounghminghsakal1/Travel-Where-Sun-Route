enum ZoneRank {
  first('1st Preference'),
  second('2nd Preference'),
  third('3rd Preference'),
  avoid('Avoid');

  const ZoneRank(this.label);
  final String label;
}

/// A group of adjacent seats with similar scores, presented as one choice.
class SeatZone {
  const SeatZone({
    required this.rank,
    required this.seatIds,
    required this.title,
    required this.area,
    required this.score,
    required this.reason,
    required this.shadedShare,
  });

  final ZoneRank rank;
  final List<String> seatIds;

  /// e.g. "Seats 3A–7A".
  final String title;

  /// e.g. "Left window · Front".
  final String area;
  final double score;
  final String reason;

  /// 0–1 share of daylight time the zone is out of direct sun.
  final double shadedShare;
}
