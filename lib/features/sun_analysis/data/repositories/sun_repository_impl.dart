import '../../../../core/entities/geo_point.dart';
import '../../domain/entities/sun_position.dart';
import '../../domain/repositories/sun_repository.dart';
import '../datasources/sun_calculator_data_source.dart';

class SunRepositoryImpl implements SunRepository {
  const SunRepositoryImpl(this._source);
  final SunCalculatorDataSource _source;

  @override
  SunPosition positionAt(DateTime time, GeoPoint location) {
    final a = _source.compute(time, location.lat, location.lng);
    return SunPosition(azimuth: a.azimuth, altitude: a.altitude);
  }
}
