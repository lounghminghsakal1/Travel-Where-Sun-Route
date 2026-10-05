import 'package:dio/dio.dart';

import 'failures.dart';

/// Thrown by data sources; repositories convert these into [Failure]s.
class AppException implements Exception {
  const AppException(this.failure);

  final Failure failure;

  @override
  String toString() => 'AppException(${failure.title}: ${failure.message})';
}

/// Maps any error raised during a request to a [Failure].
Failure mapErrorToFailure(Object error, {String service = 'API'}) {
  if (error is AppException) return error.failure;
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        final apiMessage = _extractMessage(error.response?.data);
        if (status == 401 || status == 403) {
          return ApiKeyFailure(
            service,
            apiMessage ?? 'The key was rejected. Check it in Settings.',
          );
        }
        if (status == 429) {
          return ServerFailure('$service rate limit reached. Try again in a minute.');
        }
        return ServerFailure(apiMessage ?? '$service returned an error ($status).');
      case DioExceptionType.cancel:
        return const ServerFailure('Request was cancelled.');
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return const NetworkFailure();
    }
  }
  return ServerFailure(error.toString());
}

String? _extractMessage(Object? data) {
  if (data is Map) {
    final error = data['error'];
    if (error is Map && error['message'] is String) return error['message'] as String;
    if (data['error_message'] is String) return data['error_message'] as String;
    if (data['message'] is String) return data['message'] as String;
  }
  return null;
}
