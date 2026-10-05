import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/entities/geo_point.dart';
import '../../../../injection.dart';
import '../../../seat_scoring/domain/entities/vehicle_layout.dart';
import '../../data/datasources/route_history_local_data_source.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/trip_request.dart';

class RouteFormState {
  const RouteFormState({
    this.origin,
    this.destination,
    required this.departure,
    this.vehicle = VehicleType.bus,
    this.departureEdited = false,
  });

  final Place? origin;
  final Place? destination;
  final DateTime departure;
  final VehicleType vehicle;

  /// False while [departure] is still the automatic "in 30 minutes" default.
  final bool departureEdited;

  bool get isComplete => origin != null && destination != null;

  TripRequest? toRequest() => isComplete
      ? TripRequest(
          origin: origin!,
          destination: destination!,
          departure: departure,
          vehicle: vehicle,
        )
      : null;

  RouteFormState copyWith({
    Place? origin,
    Place? destination,
    DateTime? departure,
    VehicleType? vehicle,
    bool? departureEdited,
    bool clearOrigin = false,
    bool clearDestination = false,
  }) =>
      RouteFormState(
        origin: clearOrigin ? null : (origin ?? this.origin),
        destination: clearDestination ? null : (destination ?? this.destination),
        departure: departure ?? this.departure,
        vehicle: vehicle ?? this.vehicle,
        departureEdited: departureEdited ?? this.departureEdited,
      );
}

final routeFormProvider =
    NotifierProvider<RouteFormNotifier, RouteFormState>(RouteFormNotifier.new);

class RouteFormNotifier extends Notifier<RouteFormState> {
  @override
  RouteFormState build() => RouteFormState(departure: defaultDeparture());

  /// Now + 30 min, rounded up to the next 5 minutes.
  static DateTime defaultDeparture() {
    final t = DateTime.now().add(const Duration(minutes: 30));
    final rounded = (t.minute / 5).ceil() * 5;
    return DateTime(t.year, t.month, t.day, t.hour).add(Duration(minutes: rounded));
  }

  void setOrigin(Place p) => state = state.copyWith(origin: p);
  void setDestination(Place p) => state = state.copyWith(destination: p);
  void setDeparture(DateTime t) => state = state.copyWith(departure: t, departureEdited: true);

  /// Re-derives the default departure if the app sat open long enough for it
  /// to drift into the past and the user never chose a time.
  void refreshDefaultDeparture() {
    if (!state.departureEdited && state.departure.isBefore(DateTime.now().add(const Duration(minutes: 5)))) {
      state = state.copyWith(departure: defaultDeparture());
    }
  }
  void setVehicle(VehicleType v) => state = state.copyWith(vehicle: v);

  void swap() => state = RouteFormState(
        origin: state.destination,
        destination: state.origin,
        departure: state.departure,
        vehicle: state.vehicle,
        departureEdited: state.departureEdited,
      );

  void applyTrip(RecentTrip trip) => state = state.copyWith(
        origin: trip.origin,
        destination: trip.destination,
        vehicle: trip.vehicle,
      );
}

/// Recent places and trips from local storage, refreshed after each write.
final recentPlacesProvider =
    NotifierProvider<RecentPlacesNotifier, List<Place>>(RecentPlacesNotifier.new);

class RecentPlacesNotifier extends Notifier<List<Place>> {
  @override
  List<Place> build() => ref.watch(routeHistoryProvider).recentPlaces();

  Future<void> add(Place p) async {
    await ref.read(routeHistoryProvider).addPlace(p);
    state = ref.read(routeHistoryProvider).recentPlaces();
  }
}

final recentTripsProvider =
    NotifierProvider<RecentTripsNotifier, List<RecentTrip>>(RecentTripsNotifier.new);

class RecentTripsNotifier extends Notifier<List<RecentTrip>> {
  @override
  List<RecentTrip> build() => ref.watch(routeHistoryProvider).recentTrips();

  Future<void> add(RecentTrip t) async {
    await ref.read(routeHistoryProvider).addTrip(t);
    state = ref.read(routeHistoryProvider).recentTrips();
  }

  Future<void> clear() async {
    await ref.read(routeHistoryProvider).clear();
    state = const [];
    ref.invalidate(recentPlacesProvider);
  }
}

/// Ready-made trips so first-time users can try the app in one tap.
const sampleTrips = [
  RecentTrip(
    Place(id: 'sample:blr', name: 'Bengaluru', address: 'Bengaluru, Karnataka, India', location: GeoPoint(12.9716, 77.5946)),
    Place(id: 'sample:mys', name: 'Mysuru', address: 'Mysuru, Karnataka, India', location: GeoPoint(12.2958, 76.6394)),
    VehicleType.bus,
  ),
  RecentTrip(
    Place(id: 'sample:bom', name: 'Mumbai', address: 'Mumbai, Maharashtra, India', location: GeoPoint(19.0760, 72.8777)),
    Place(id: 'sample:pnq', name: 'Pune', address: 'Pune, Maharashtra, India', location: GeoPoint(18.5204, 73.8567)),
    VehicleType.car4,
  ),
  RecentTrip(
    Place(id: 'sample:del', name: 'New Delhi', address: 'New Delhi, Delhi, India', location: GeoPoint(28.6139, 77.2090)),
    Place(id: 'sample:jai', name: 'Jaipur', address: 'Jaipur, Rajasthan, India', location: GeoPoint(26.9124, 75.7873)),
    VehicleType.train,
  ),
];
