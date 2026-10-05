import '../../../../config/bus_layout.dart';
import '../../../../config/car4_layout.dart';
import '../../../../config/car5_layout.dart';
import '../../../../config/train_layout.dart';
import '../../domain/entities/vehicle_layout.dart';

/// Static vehicle configurations, built once per driver position.
class VehicleLayoutDataSource {
  final _cache = <(VehicleType, DriverPosition), VehicleLayout>{};

  VehicleLayout layoutFor(VehicleType type, DriverPosition driver) =>
      _cache.putIfAbsent((type, driver), () {
        return switch (type) {
          VehicleType.bus => buildBusLayout(driver),
          VehicleType.train => buildTrainLayout(),
          VehicleType.car4 => buildCar4Layout(driver),
          VehicleType.car5plus => buildCar5Layout(driver),
        };
      });
}
