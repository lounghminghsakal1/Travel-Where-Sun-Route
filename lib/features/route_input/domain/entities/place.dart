import 'package:equatable/equatable.dart';

import '../../../../core/entities/geo_point.dart';

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
  });

  final String placeId;
  final String primaryText;
  final String secondaryText;
}

class Place extends Equatable {
  const Place({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
  });

  final String id;
  final String name;
  final String address;
  final GeoPoint location;

  @override
  List<Object?> get props => [id, location];
}
