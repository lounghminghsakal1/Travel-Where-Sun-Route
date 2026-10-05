import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Identifies the installed app to Google so REST calls (Places, Routes)
/// work with an API key restricted to this Android/iOS app.
class AppIdentity {
  const AppIdentity._();

  static const _channel = MethodChannel('sunroute/app_identity');

  static Map<String, String> googleHeaders = const {};

  static Future<void> load() async {
    if (kIsWeb) return;
    try {
      final info = await _channel.invokeMapMethod<String, dynamic>('getIdentity');
      if (info == null) return;
      final headers = <String, String>{};
      final package = info['packageName'] as String?;
      final sha1 = info['certSha1'] as String?;
      final bundle = info['bundleId'] as String?;
      if (package != null && package.isNotEmpty) headers['X-Android-Package'] = package;
      if (sha1 != null && sha1.isNotEmpty) headers['X-Android-Cert'] = sha1;
      if (bundle != null && bundle.isNotEmpty) headers['X-Ios-Bundle-Identifier'] = bundle;
      googleHeaders = headers;
    } on MissingPluginException {
      // Desktop: no native channel, keys must be unrestricted or IP-restricted.
    } on PlatformException catch (e) {
      debugPrint('App identity unavailable: ${e.message}');
    }
  }
}

/// Adds [AppIdentity.googleHeaders] to requests for Google APIs.
class GoogleIdentityInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.uri.host.endsWith('googleapis.com')) {
      options.headers.addAll(AppIdentity.googleHeaders);
    }
    handler.next(options);
  }
}
