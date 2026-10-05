import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/dio_client.dart';
import 'core/storage/preferences.dart';
import 'features/route_input/data/datasources/directions_remote_data_source.dart';
import 'features/route_input/data/datasources/places_remote_data_source.dart';
import 'features/route_input/data/datasources/route_history_local_data_source.dart';
import 'features/route_input/data/repositories/route_repository_impl.dart';
import 'features/route_input/domain/repositories/route_repository.dart';
import 'features/route_input/domain/usecases/get_route.dart';
import 'features/route_input/domain/usecases/search_places.dart';
import 'features/seat_scoring/data/datasources/vehicle_layout_data_source.dart';
import 'features/seat_scoring/data/repositories/seat_repository_impl.dart';
import 'features/seat_scoring/domain/repositories/seat_repository.dart';
import 'features/seat_scoring/domain/usecases/compute_seat_scores.dart';
import 'features/seat_scoring/domain/usecases/get_seat_recommendations.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/sun_analysis/data/datasources/sun_calculator_data_source.dart';
import 'features/sun_analysis/data/repositories/sun_repository_impl.dart';
import 'features/sun_analysis/domain/repositories/sun_repository.dart';
import 'features/sun_analysis/domain/usecases/compute_sun_positions.dart';
import 'features/weather/data/datasources/weather_remote_data_source.dart';
import 'features/weather/data/repositories/weather_repository_impl.dart';
import 'features/weather/domain/repositories/weather_repository.dart';
import 'features/weather/domain/usecases/get_weather_along_route.dart';

// ---------------------------------------------------------------- core

final dioProvider = Provider<Dio>((ref) {
  final dio = createDio();
  ref.onDispose(dio.close);
  return dio;
});

// ---------------------------------------------------------------- data

final placesDataSourceProvider = Provider<PlacesRemoteDataSource>((ref) =>
    PlacesRemoteDataSource(ref.watch(dioProvider), () => ref.read(googleApiKeyProvider)));

final directionsDataSourceProvider = Provider<DirectionsRemoteDataSource>((ref) =>
    DirectionsRemoteDataSource(ref.watch(dioProvider), () => ref.read(googleApiKeyProvider)));

final routeHistoryProvider = Provider<RouteHistoryLocalDataSource>(
  (ref) => RouteHistoryLocalDataSource(ref.watch(sharedPreferencesProvider)),
);

final weatherDataSourceProvider = Provider<WeatherRemoteDataSource>((ref) =>
    WeatherRemoteDataSource(ref.watch(dioProvider), () => ref.read(weatherApiKeyProvider)));

// ---------------------------------------------------------------- repositories

final routeRepositoryProvider = Provider<RouteRepository>((ref) => RouteRepositoryImpl(
      ref.watch(placesDataSourceProvider),
      ref.watch(directionsDataSourceProvider),
    ));

final weatherRepositoryImplProvider = Provider<WeatherRepositoryImpl>((ref) =>
    WeatherRepositoryImpl(ref.watch(weatherDataSourceProvider), ref.watch(sharedPreferencesProvider)));

final weatherRepositoryProvider =
    Provider<WeatherRepository>((ref) => ref.watch(weatherRepositoryImplProvider));

final sunRepositoryProvider = Provider<SunRepository>(
  (ref) => const SunRepositoryImpl(SunCalculatorDataSource()),
);

final seatRepositoryProvider = Provider<SeatRepository>(
  (ref) => SeatRepositoryImpl(VehicleLayoutDataSource()),
);

// ---------------------------------------------------------------- use cases

final searchPlacesProvider =
    Provider<SearchPlaces>((ref) => SearchPlaces(ref.watch(routeRepositoryProvider)));

final getPlaceDetailsProvider =
    Provider<GetPlaceDetails>((ref) => GetPlaceDetails(ref.watch(routeRepositoryProvider)));

final getRouteProvider =
    Provider<GetRoute>((ref) => GetRoute(ref.watch(routeRepositoryProvider)));

final computeSunPositionsProvider = Provider<ComputeSunPositions>(
  (ref) => ComputeSunPositions(ref.watch(sunRepositoryProvider)),
);

final getWeatherAlongRouteProvider = Provider<GetWeatherAlongRoute>(
  (ref) => GetWeatherAlongRoute(ref.watch(weatherRepositoryProvider)),
);

final computeSeatScoresProvider = Provider((ref) => const ComputeSeatScores());

final getSeatRecommendationsProvider = Provider((ref) => const GetSeatRecommendations());
