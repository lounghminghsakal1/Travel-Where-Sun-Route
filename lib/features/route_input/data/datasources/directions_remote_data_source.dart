import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/entities/geo_point.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/route_info.dart';
import '../models/route_model.dart';

/// Gets a driving route. Tries Google Routes API first; if the key isn't
/// authorised for it, falls back to the public OSRM router.
class DirectionsRemoteDataSource {
  DirectionsRemoteDataSource(this._dio, this._apiKey);

  final Dio _dio;
  final String Function() _apiKey;

  /// Set after Google rejects the key so later searches skip straight to OSRM.
  bool _googleRejected = false;

  Future<RouteInfo> getRoute({
    required GeoPoint origin,
    required GeoPoint destination,
    required DateTime departure,
  }) async {
    final key = _apiKey();
    if (key.isNotEmpty && !_googleRejected) {
      try {
        final route = await _google(origin, destination, key);
        if (route != null && route.points.length > 1) return route;
      } on DioException catch (e) {
        final status = e.response?.statusCode ?? 0;
        if (status >= 400 && status < 500) _googleRejected = true;
        debugPrint('Google Routes unavailable ($status); using OSRM.');
      }
    }
    return _osrm(origin, destination);
  }

  Future<RouteInfo?> _google(GeoPoint o, GeoPoint d, String key) async {
    Map<String, dynamic> waypoint(GeoPoint p) => {
          'location': {
            'latLng': {'latitude': p.lat, 'longitude': p.lng},
          },
        };
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.googleRoutes,
      data: {
        'origin': waypoint(o),
        'destination': waypoint(d),
        'travelMode': 'DRIVE',
        'polylineEncoding': 'ENCODED_POLYLINE',
      },
      options: Options(headers: {
        'X-Goog-Api-Key': key,
        'X-Goog-FieldMask':
            'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline',
      }),
    );
    return RouteModel.fromGoogleRoutes(response.data ?? const {});
  }

  Future<RouteInfo> _osrm(GeoPoint o, GeoPoint d) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiConstants.osrmRoute}/${o.lng},${o.lat};${d.lng},${d.lat}',
        queryParameters: {
          'overview': 'full',
          'geometries': 'geojson',
          'annotations': 'duration',
        },
      );
      final route = RouteModel.fromOsrm(response.data ?? const {});
      if (route == null || route.points.length < 2) {
        throw const AppException(NoRouteFailure());
      }
      return route;
    } on DioException catch (e) {
      // OSRM answers 400 with code "NoRoute" for unreachable pairs.
      final data = e.response?.data;
      if (data is Map && (data['code'] == 'NoRoute' || data['code'] == 'NoSegment')) {
        throw const AppException(NoRouteFailure());
      }
      rethrow;
    }
  }
}
