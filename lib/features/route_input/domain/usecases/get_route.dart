import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/route_info.dart';
import '../entities/trip_request.dart';
import '../repositories/route_repository.dart';

class GetRoute {
  const GetRoute(this._repository);
  final RouteRepository _repository;

  Future<Result<RouteInfo>> call(TripRequest request) async {
    if (request.origin.location == request.destination.location) {
      return const Err(NoRouteFailure('Origin and destination are the same place.'));
    }
    return _repository.getRoute(
      request.origin.location,
      request.destination.location,
      departure: request.departure,
    );
  }
}
