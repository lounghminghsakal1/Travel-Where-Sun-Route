enum SeatSide { left, right, middle }

class Seat {
  const Seat({
    required this.id,
    required this.label,
    required this.row,
    required this.column,
    required this.side,
    required this.isWindow,
    required this.isAisle,
    required this.hasVentilation,
    required this.x,
    required this.y,
    this.isDriver = false,
  });

  final String id;

  /// Human label, e.g. "Rear left" for cars or "4A" for buses.
  final String label;
  final int row;
  final String column;
  final SeatSide side;
  final bool isWindow;
  final bool isAisle;

  /// Whether the seat has an openable window next to it.
  final bool hasVentilation;

  /// Seat centre in body-normalised coordinates: x 0 (left) → 1 (right),
  /// y 0 (front bumper) → 1 (rear bumper).
  final double x;
  final double y;
  final bool isDriver;

  bool get isMiddle => side == SeatSide.middle;
}
