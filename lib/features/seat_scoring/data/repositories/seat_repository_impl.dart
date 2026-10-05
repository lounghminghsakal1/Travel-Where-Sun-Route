import '../../domain/entities/vehicle_layout.dart';
import '../../domain/repositories/seat_repository.dart';
import '../datasources/vehicle_layout_data_source.dart';

class SeatRepositoryImpl implements SeatRepository {
  SeatRepositoryImpl(this._source);
  final VehicleLayoutDataSource _source;

  @override
  VehicleLayout getLayout(VehicleType type, DriverPosition driver) =>
      _source.layoutFor(type, driver);
}
