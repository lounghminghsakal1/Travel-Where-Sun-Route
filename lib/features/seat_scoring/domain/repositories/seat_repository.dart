import '../entities/vehicle_layout.dart';

abstract interface class SeatRepository {
  VehicleLayout getLayout(VehicleType type, DriverPosition driver);
}
