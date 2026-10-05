import '../../../../core/entities/geo_point.dart';
import '../entities/sun_position.dart';

abstract interface class SunRepository {
  SunPosition positionAt(DateTime time, GeoPoint location);
}
