import '../features/seat_scoring/domain/entities/seat.dart';
import '../features/seat_scoring/domain/entities/vehicle_layout.dart';

/// 49-seat coach: 11 rows of 2+2 and a 5-seat rear bench.
VehicleLayout buildBusLayout(DriverPosition driver) {
  const rows = 12;
  const firstRowY = 0.19;
  const lastRowY = 0.955;
  const pitch = (lastRowY - firstRowY) / (rows - 1);
  final driverOnRight = driver == DriverPosition.right;

  final seats = <Seat>[
    Seat(
      id: 'DRV',
      label: 'Driver',
      row: 0,
      column: '-',
      side: driverOnRight ? SeatSide.right : SeatSide.left,
      isWindow: true,
      isAisle: false,
      hasVentilation: true,
      x: driverOnRight ? 0.80 : 0.20,
      y: 0.085,
      isDriver: true,
    ),
  ];

  const columns = {
    'A': (x: 0.13, side: SeatSide.left, window: true),
    'B': (x: 0.31, side: SeatSide.left, window: false),
    'C': (x: 0.69, side: SeatSide.right, window: false),
    'D': (x: 0.87, side: SeatSide.right, window: true),
  };

  for (var r = 1; r < rows; r++) {
    final y = firstRowY + (r - 1) * pitch;
    columns.forEach((col, c) {
      seats.add(Seat(
        id: '$r$col',
        label: '$r$col',
        row: r,
        column: col,
        side: c.side,
        isWindow: c.window,
        isAisle: !c.window,
        hasVentilation: c.window,
        x: c.x,
        y: y,
      ));
    });
  }

  const rear = {
    'A': (x: 0.12, side: SeatSide.left, window: true),
    'B': (x: 0.31, side: SeatSide.left, window: false),
    'C': (x: 0.50, side: SeatSide.middle, window: false),
    'D': (x: 0.69, side: SeatSide.right, window: false),
    'E': (x: 0.88, side: SeatSide.right, window: true),
  };
  rear.forEach((col, c) {
    seats.add(Seat(
      id: '$rows$col',
      label: '$rows$col',
      row: rows,
      column: col,
      side: c.side,
      isWindow: c.window,
      isAisle: !c.window && c.side != SeatSide.middle,
      hasVentilation: c.window,
      x: c.x,
      y: lastRowY,
    ));
  });

  return VehicleLayout(
    type: VehicleType.bus,
    name: 'Coach bus · 49 seats',
    rows: rows,
    seatsPerRow: 4,
    seatMap: seats,
    lengthRatio: 3.0,
    seatWidth: 0.155,
    seatHeight: 0.05,
    hasWindshield: true,
    hasRearWindow: false,
    firstRowY: firstRowY,
    lastRowY: lastRowY,
    windshieldReach: 0.2,
    exitRows: const {1, 2},
    doorYs: const [0.13],
    doorOnLeft: driverOnRight,
  );
}
