import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../seat_scoring/domain/entities/vehicle_layout.dart';
import '../../domain/entities/place.dart';
import '../models/place_model.dart';

class RecentTrip {
  const RecentTrip(this.origin, this.destination, this.vehicle);
  final Place origin;
  final Place destination;
  final VehicleType vehicle;
}

/// Recently picked places and searched trips, kept on device.
class RouteHistoryLocalDataSource {
  RouteHistoryLocalDataSource(this._prefs);
  final SharedPreferences _prefs;

  static const _placesKey = 'recent_places';
  static const _tripsKey = 'recent_trips';

  List<Place> recentPlaces() => _readList(_placesKey)
      .map((e) => PlaceModel.fromJson(e))
      .toList(growable: false);

  Future<void> addPlace(Place place) async {
    final places = recentPlaces().where((p) => p.id != place.id).toList()
      ..insert(0, place);
    await _prefs.setString(
      _placesKey,
      jsonEncode(places.take(8).map(PlaceModel.toJson).toList()),
    );
  }

  List<RecentTrip> recentTrips() => _readList(_tripsKey)
      .map((e) => RecentTrip(
            PlaceModel.fromJson(e['origin'] as Map<String, dynamic>),
            PlaceModel.fromJson(e['destination'] as Map<String, dynamic>),
            VehicleType.values.byName(e['vehicle'] as String),
          ))
      .toList(growable: false);

  Future<void> addTrip(RecentTrip trip) async {
    final trips = recentTrips()
        .where((t) =>
            !(t.origin.id == trip.origin.id &&
                t.destination.id == trip.destination.id &&
                t.vehicle == trip.vehicle))
        .toList()
      ..insert(0, trip);
    await _prefs.setString(
      _tripsKey,
      jsonEncode([
        for (final t in trips.take(5))
          {
            'origin': PlaceModel.toJson(t.origin),
            'destination': PlaceModel.toJson(t.destination),
            'vehicle': t.vehicle.name,
          },
      ]),
    );
  }

  Future<void> clear() async {
    await _prefs.remove(_placesKey);
    await _prefs.remove(_tripsKey);
  }

  List<Map<String, dynamic>> _readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }
}
