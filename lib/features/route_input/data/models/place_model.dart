import '../../../../core/entities/geo_point.dart';
import '../../domain/entities/place.dart';

/// JSON mapping for Google Places API (New) and local persistence.
class PlaceModel {
  const PlaceModel._();

  static PlaceSuggestion suggestionFromJson(Map<dynamic, dynamic> prediction) {
    final structured = (prediction['structuredFormat'] as Map?) ?? const {};
    final main = (structured['mainText'] as Map?)?['text'] as String?;
    final secondary = (structured['secondaryText'] as Map?)?['text'] as String?;
    final full = (prediction['text'] as Map?)?['text'] as String? ?? '';
    return PlaceSuggestion(
      placeId: prediction['placeId'] as String? ?? '',
      primaryText: main ?? full,
      secondaryText: secondary ?? '',
    );
  }

  static Place placeFromJson(Map<dynamic, dynamic> json) {
    final location = (json['location'] as Map?) ?? const {};
    return Place(
      id: json['id'] as String? ?? '',
      name: (json['displayName'] as Map?)?['text'] as String? ?? '',
      address: json['formattedAddress'] as String? ?? '',
      location: GeoPoint(
        (location['latitude'] as num?)?.toDouble() ?? 0,
        (location['longitude'] as num?)?.toDouble() ?? 0,
      ),
    );
  }

  static Map<String, dynamic> toJson(Place p) => {
        'id': p.id,
        'name': p.name,
        'address': p.address,
        'location': p.location.toJson(),
      };

  static Place fromJson(Map<String, dynamic> json) => Place(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        location: GeoPoint.fromJson(json['location'] as Map<String, dynamic>),
      );
}
