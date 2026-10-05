import '../features/seat_scoring/domain/entities/seat.dart';
import '../features/seat_scoring/domain/entities/vehicle_layout.dart';

/// Hatchback/sedan: driver + 3 choosable seats.
VehicleLayout buildCar4Layout(DriverPosition driver) {
  const frontY = 0.43;
  const rearY = 0.665;
  final driverOnRight = driver == DriverPosition.right;
  final driverX = driverOnRight ? 0.7 : 0.3;
  final passengerX = driverOnRight ? 0.3 : 0.7;
  final passengerSide = driverOnRight ? SeatSide.left : SeatSide.right;

  final seats = [
    Seat(
      id: 'DRV',
      label: 'Driver',
      row: 1,
      column: driverOnRight ? 'R' : 'L',
      side: driverOnRight ? SeatSide.right : SeatSide.left,
      isWindow: true,
      isAisle: false,
      hasVentilation: true,
      x: driverX,
      y: frontY,
      isDriver: true,
    ),
    Seat(
      id: 'FP',
      label: 'Front passenger',
      row: 1,
      column: driverOnRight ? 'L' : 'R',
      side: passengerSide,
      isWindow: true,
      isAisle: false,
      hasVentilation: true,
      x: passengerX,
      y: frontY,
    ),
    const Seat(
      id: 'RL',
      label: 'Rear left',
      row: 2,
      column: 'L',
      side: SeatSide.left,
      isWindow: true,
      isAisle: false,
      hasVentilation: true,
      x: 0.3,
      y: rearY,
    ),
    const Seat(
      id: 'RR',
      label: 'Rear right',
      row: 2,
      column: 'R',
      side: SeatSide.right,
      isWindow: true,
      isAisle: false,
      hasVentilation: true,
      x: 0.7,
      y: rearY,
    ),
  ];

  return VehicleLayout(
    type: VehicleType.car4,
    name: 'Car · 4 seats',
    rows: 2,
    seatsPerRow: 2,
    seatMap: seats,
    lengthRatio: 2.25,
    seatWidth: 0.3,
    seatHeight: 0.13,
    hasWindshield: true,
    hasRearWindow: true,
    firstRowY: frontY,
    lastRowY: rearY,
    windshieldReach: 0.4,
    rearWindowReach: 0.3,
    exitRows: const {1, 2},
  );
}
