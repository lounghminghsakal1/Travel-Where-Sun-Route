import 'package:equatable/equatable.dart';

import '../../../seat_scoring/domain/entities/vehicle_layout.dart';
import 'place.dart';

class TripRequest extends Equatable {
  const TripRequest({
    required this.origin,
    required this.destination,
    required this.departure,
    required this.vehicle,
  });

  final Place origin;
  final Place destination;
  final DateTime departure;
  final VehicleType vehicle;

  @override
  List<Object?> get props => [origin, destination, departure, vehicle];
}
