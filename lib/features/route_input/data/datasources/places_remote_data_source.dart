import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/place.dart';
import '../models/place_model.dart';

/// Google Places API (New): autocomplete + place details.
class PlacesRemoteDataSource {
  PlacesRemoteDataSource(this._dio, this._apiKey);

  final Dio _dio;
  final String Function() _apiKey;

  String _requireKey() {
    final key = _apiKey();
    if (key.isEmpty) {
      throw const AppException(
        ApiKeyFailure('Google', 'No Google API key set. Add one in Settings to search places.'),
      );
    }
    return key;
  }

  Future<List<PlaceSuggestion>> autocomplete(String input, String sessionToken) async {
    final key = _requireKey();
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.placesAutocomplete,
      data: {'input': input, 'sessionToken': sessionToken},
      options: Options(headers: {'X-Goog-Api-Key': key}),
    );
    final suggestions = (response.data?['suggestions'] as List?) ?? const [];
    return [
      for (final s in suggestions)
        if (s is Map && s['placePrediction'] is Map)
          PlaceModel.suggestionFromJson(s['placePrediction'] as Map),
    ];
  }

  Future<Place> details(String placeId, String sessionToken) async {
    final key = _requireKey();
    final response = await _dio.get<Map<String, dynamic>>(
      ApiConstants.placeDetails(placeId),
      queryParameters: {
        // displayName would bill as Place Details Pro; the suggestion text
        // supplies the name, keeping this on the cheaper Essentials SKU.
        'fields': 'id,formattedAddress,location',
        'sessionToken': sessionToken,
      },
      options: Options(headers: {'X-Goog-Api-Key': key}),
    );
    return PlaceModel.placeFromJson(response.data ?? const {});
  }
}
