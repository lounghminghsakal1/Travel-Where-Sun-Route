import '../../../../core/entities/geo_point.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/route_info.dart';
import '../../domain/repositories/route_repository.dart';
import '../datasources/directions_remote_data_source.dart';
import '../datasources/places_remote_data_source.dart';

class RouteRepositoryImpl implements RouteRepository {
  RouteRepositoryImpl(this._places, this._directions);

  final PlacesRemoteDataSource _places;
  final DirectionsRemoteDataSource _directions;

  @override
  Future<Result<List<PlaceSuggestion>>> searchPlaces(
    String query, {
    required String sessionToken,
  }) async {
    try {
      return Ok(await _places.autocomplete(query, sessionToken));
    } catch (e) {
      return Err(mapErrorToFailure(e, service: 'Google Places'));
    }
  }

  @override
  Future<Result<Place>> getPlace(String placeId, {required String sessionToken}) async {
    try {
      return Ok(await _places.details(placeId, sessionToken));
    } catch (e) {
      return Err(mapErrorToFailure(e, service: 'Google Places'));
    }
  }

  @override
  Future<Result<RouteInfo>> getRoute(
    GeoPoint origin,
    GeoPoint destination, {
    required DateTime departure,
  }) async {
    try {
      return Ok(await _directions.getRoute(
        origin: origin,
        destination: destination,
        departure: departure,
      ));
    } catch (e) {
      return Err(mapErrorToFailure(e, service: 'Routing'));
    }
  }
}
