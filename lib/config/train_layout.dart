import '../features/seat_scoring/domain/entities/seat.dart';
import '../features/seat_scoring/domain/entities/vehicle_layout.dart';

/// One standard 72-seat coach: 18 rows of 2+2, facing pairs around tables.
VehicleLayout buildTrainLayout() {
  const pairs = 9;
  const firstPairY = 0.075;
  const pairPitch = 0.0967;
  const inPairOffset = 0.052;

  const columns = {
    'A': (x: 0.14, side: SeatSide.left, window: true),
    'B': (x: 0.32, side: SeatSide.left, window: false),
    'C': (x: 0.68, side: SeatSide.right, window: false),
    'D': (x: 0.86, side: SeatSide.right, window: true),
  };

  final seats = <Seat>[];
  final tables = <double>[];
  for (var p = 0; p < pairs; p++) {
    final start = firstPairY + p * pairPitch;
    tables.add(start + inPairOffset / 2);
    for (var k = 0; k < 2; k++) {
      final row = p * 2 + k + 1;
      final y = start + k * inPairOffset;
      columns.forEach((col, c) {
        seats.add(Seat(
          id: '$row$col',
          label: '$row$col',
          row: row,
          column: col,
          side: c.side,
          isWindow: c.window,
          isAisle: !c.window,
          hasVentilation: false,
          x: c.x,
          y: y,
        ));
      });
    }
  }

  return VehicleLayout(
    type: VehicleType.train,
    name: 'Chair-car coach · 72 seats',
    rows: pairs * 2,
    seatsPerRow: 4,
    seatMap: seats,
    lengthRatio: 4.2,
    seatWidth: 0.165,
    seatHeight: 0.036,
    hasWindshield: false,
    hasRearWindow: false,
    firstRowY: firstPairY,
    lastRowY: firstPairY + (pairs - 1) * pairPitch + inPairOffset,
    exitRows: const {1, 2, 17, 18},
    tableYs: tables,
    doorYs: const [0.025, 0.975],
    isAirConditioned: true,
  );
}
