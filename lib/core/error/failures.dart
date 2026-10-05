/// User-presentable failures returned from repositories.
sealed class Failure {
  const Failure(this.message);

  final String message;

  String get title;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Check your internet connection and try again.']);

  @override
  String get title => 'You appear to be offline';
}

class ApiKeyFailure extends Failure {
  const ApiKeyFailure(this.service, super.message);

  final String service;

  @override
  String get title => '$service API key problem';
}

class NoRouteFailure extends Failure {
  const NoRouteFailure([super.message = 'We could not find a drivable route between these places.']);

  @override
  String get title => 'No route found';
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);

  @override
  String get title => 'Something went wrong';
}
