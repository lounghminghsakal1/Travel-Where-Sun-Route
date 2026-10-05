import '../features/seat_scoring/domain/entities/seat.dart';
import '../features/seat_scoring/domain/entities/vehicle_layout.dart';

/// 7-seater SUV/MPV: driver + passenger, 3-seat bench, 2-seat third row.
VehicleLayout buildCar5Layout(DriverPosition driver) {
  const row1 = 0.34;
  const row2 = 0.535;
  const row3 = 0.725;
  final driverOnRight = driver == DriverPosition.right;

  Seat seat(String id, String label, int row, String col, SeatSide side,
          double x, double y,
          {bool window = true, bool vent = true, bool isDriver = false}) =>
      Seat(
        id: id,
        label: label,
        row: row,
        column: col,
        side: side,
        isWindow: window,
        isAisle: false,
        hasVentilation: vent,
        x: x,
        y: y,
        isDriver: isDriver,
      );

  final seats = [
    seat('DRV', 'Driver', 1, driverOnRight ? 'R' : 'L',
        driverOnRight ? SeatSide.right : SeatSide.left,
        driverOnRight ? 0.7 : 0.3, row1,
        isDriver: true),
    seat('FP', 'Front passenger', 1, driverOnRight ? 'L' : 'R',
        driverOnRight ? SeatSide.left : SeatSide.right,
        driverOnRight ? 0.3 : 0.7, row1),
    seat('2L', 'Middle row left', 2, 'L', SeatSide.left, 0.22, row2),
    seat('2M', 'Middle row centre', 2, 'M', SeatSide.middle, 0.5, row2,
        window: false, vent: false),
    seat('2R', 'Middle row right', 2, 'R', SeatSide.right, 0.78, row2),
    seat('3L', 'Third row left', 3, 'L', SeatSide.left, 0.3, row3, vent: false),
    seat('3R', 'Third row right', 3, 'R', SeatSide.right, 0.7, row3, vent: false),
  ];

  return VehicleLayout(
    type: VehicleType.car5plus,
    name: 'SUV / MPV · 7 seats',
    rows: 3,
    seatsPerRow: 3,
    seatMap: seats,
    lengthRatio: 2.55,
    seatWidth: 0.25,
    seatHeight: 0.105,
    hasWindshield: true,
    hasRearWindow: true,
    firstRowY: row1,
    lastRowY: row3,
    windshieldReach: 0.45,
    rearWindowReach: 0.22,
    exitRows: const {1, 2},
  );
}
