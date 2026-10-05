import 'package:dio/dio.dart';

import 'app_identity.dart';

/// Shared Dio instance with sensible timeouts and a small retry policy for
/// transient failures. API keys are attached per request by data sources.
Dio createDio() {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 25),
      sendTimeout: const Duration(seconds: 12),
      responseType: ResponseType.json,
    ),
  );
  dio.interceptors
    ..add(GoogleIdentityInterceptor())
    ..add(RetryInterceptor(dio));
  return dio;
}

class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._dio, {this.maxRetries = 2});

  final Dio _dio;
  final int maxRetries;

  static const _attemptKey = 'retry_attempt';

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;
    if (!_isTransient(err) || attempt >= maxRetries) {
      return handler.next(err);
    }
    await Future<void>.delayed(Duration(milliseconds: 500 * (attempt + 1)));
    options.extra[_attemptKey] = attempt + 1;
    try {
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  bool _isTransient(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode ?? 0;
        return status >= 500;
      default:
        return false;
    }
  }
}
