import '../../../../core/entities/geo_point.dart';
import '../../../../core/error/result.dart';
import '../entities/place.dart';
import '../entities/route_info.dart';

abstract interface class RouteRepository {
  Future<Result<List<PlaceSuggestion>>> searchPlaces(
    String query, {
    required String sessionToken,
  });

  Future<Result<Place>> getPlace(String placeId, {required String sessionToken});

  Future<Result<RouteInfo>> getRoute(
    GeoPoint origin,
    GeoPoint destination, {
    required DateTime departure,
  });
}
