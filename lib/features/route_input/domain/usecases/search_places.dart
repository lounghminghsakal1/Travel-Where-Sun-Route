import '../../../../core/error/result.dart';
import '../entities/place.dart';
import '../repositories/route_repository.dart';

class SearchPlaces {
  const SearchPlaces(this._repository);
  final RouteRepository _repository;

  Future<Result<List<PlaceSuggestion>>> call(String query, String sessionToken) {
    final trimmed = query.trim();
    if (trimmed.length < 2) return Future.value(const Ok([]));
    return _repository.searchPlaces(trimmed, sessionToken: sessionToken);
  }
}

class GetPlaceDetails {
  const GetPlaceDetails(this._repository);
  final RouteRepository _repository;

  Future<Result<Place>> call(String placeId, String sessionToken) =>
      _repository.getPlace(placeId, sessionToken: sessionToken);
}
