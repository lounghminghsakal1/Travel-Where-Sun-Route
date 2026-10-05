import 'seat.dart';

enum VehicleType {
  bus('Bus', 'Coach bus', 49),
  train('Train', 'Chair-car coach', 72),
  car4('Car', '4-seater', 4),
  car5plus('SUV', '7-seater MPV', 7);

  const VehicleType(this.label, this.subtitle, this.capacity);

  final String label;
  final String subtitle;
  final int capacity;

  /// Multiplier on road-routing duration (buses are slower, trains faster).
  double get durationFactor => switch (this) {
        VehicleType.bus => 1.2,
        VehicleType.train => 0.9,
        VehicleType.car4 => 1.0,
        VehicleType.car5plus => 1.05,
      };

  bool get isCar => this == VehicleType.car4 || this == VehicleType.car5plus;
}

/// Which side of the vehicle the driver sits on.
enum DriverPosition { left, right }

class VehicleLayout {
  const VehicleLayout({
    required this.type,
    required this.name,
    required this.rows,
    required this.seatsPerRow,
    required this.seatMap,
    required this.lengthRatio,
    required this.seatWidth,
    required this.seatHeight,
    required this.hasWindshield,
    required this.hasRearWindow,
    required this.firstRowY,
    required this.lastRowY,
    this.windshieldReach = 0.2,
    this.rearWindowReach = 0.15,
    this.exitRows = const {},
    this.tableYs = const [],
    this.doorYs = const [],
    this.doorOnLeft = true,
    this.isAirConditioned = false,
  });

  final VehicleType type;
  final String name;
  final int rows;
  final int seatsPerRow;
  final List<Seat> seatMap;

  /// Body length divided by body width (for painting).
  final double lengthRatio;

  /// Seat size, normalised to body width / body length respectively.
  final double seatWidth;
  final double seatHeight;

  final bool hasWindshield;
  final bool hasRearWindow;
  final double firstRowY;
  final double lastRowY;

  /// How far back (in normalised length) windshield light reaches.
  final double windshieldReach;
  final double rearWindowReach;

  final Set<int> exitRows;

  /// Train tables, as normalised y positions.
  final List<double> tableYs;

  /// Door positions along the body, normalised y.
  final List<double> doorYs;
  final bool doorOnLeft;
  final bool isAirConditioned;

  int get totalSeats => seatMap.length;

  Iterable<Seat> get passengerSeats => seatMap.where((s) => !s.isDriver);

  Seat? seatById(String id) {
    for (final s in seatMap) {
      if (s.id == id) return s;
    }
    return null;
  }
}
