import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/config/bus_layout.dart';
import 'package:travel_app/config/car4_layout.dart';
import 'package:travel_app/core/entities/geo_point.dart';
import 'package:travel_app/core/utils/geo_utils.dart';
import 'package:travel_app/core/utils/polyline_decoder.dart';
import 'package:travel_app/core/utils/sun_utils.dart';
import 'package:travel_app/features/route_input/domain/entities/route_info.dart';
import 'package:travel_app/features/seat_scoring/domain/entities/seat.dart';
import 'package:travel_app/features/seat_scoring/domain/entities/seat_zone.dart';
import 'package:travel_app/features/seat_scoring/domain/entities/vehicle_layout.dart';
import 'package:travel_app/features/seat_scoring/domain/usecases/compute_seat_scores.dart';
import 'package:travel_app/features/seat_scoring/domain/usecases/get_seat_recommendations.dart';
import 'package:travel_app/features/sun_analysis/data/datasources/sun_calculator_data_source.dart';
import 'package:travel_app/features/sun_analysis/data/repositories/sun_repository_impl.dart';
import 'package:travel_app/features/sun_analysis/domain/entities/journey_stats.dart';
import 'package:travel_app/features/sun_analysis/domain/entities/sun_position.dart';
import 'package:travel_app/features/sun_analysis/domain/usecases/compute_sun_positions.dart';
import 'package:travel_app/features/weather/data/models/weather_forecast_model.dart';
import 'package:travel_app/features/weather/domain/entities/weather_data.dart';

/// Straight route along a meridian from [fromLat] to [toLat].
RouteInfo _meridianRoute(double fromLat, double toLat, {double lng = 77.0, double hours = 2}) {
  const n = 120;
  final pts = [
    for (var i = 0; i <= n; i++) GeoPoint(fromLat + (toLat - fromLat) * i / n, lng),
  ];
  return RouteInfo(
    points: pts,
    distanceMeters: (toLat - fromLat).abs() * 111000,
    durationSeconds: hours * 3600,
    provider: 'test',
  );
}

void main() {
  group('SunUtils', () {
    test('June solstice noon on the equator: sun ~66.5° high in the north', () {
      final s = SunUtils.position(DateTime.utc(2024, 6, 21, 12, 2), 0, 0);
      expect(s.altitude, closeTo(66.6, 0.5));
      expect(s.azimuth < 5 || s.azimuth > 355, isTrue, reason: 'azimuth ${s.azimuth}');
    });

    test('Bengaluru morning sun is low in the east', () {
      // 07:30 IST = 02:00 UTC.
      final s = SunUtils.position(DateTime.utc(2026, 10, 5, 2, 0), 12.97, 77.59);
      expect(s.azimuth, inInclusiveRange(85, 110));
      expect(s.altitude, inInclusiveRange(10, 30));
    });

    test('Sun is below the horizon at local midnight', () {
      final s = SunUtils.position(DateTime.utc(2026, 10, 5, 18, 30), 12.97, 77.59);
      expect(s.altitude, lessThan(-30));
    });
  });

  group('Geo and polyline', () {
    test('decodes the reference polyline', () {
      final pts = PolylineDecoder.decode('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
      expect(pts, hasLength(3));
      expect(pts[0].lat, closeTo(38.5, 1e-5));
      expect(pts[0].lng, closeTo(-120.2, 1e-5));
      expect(pts[2].lat, closeTo(43.252, 1e-5));
      expect(pts[2].lng, closeTo(-126.453, 1e-5));
    });

    test('bearing and distance', () {
      expect(GeoUtils.bearing(const GeoPoint(0, 0), const GeoPoint(1, 0)), closeTo(0, 0.01));
      expect(GeoUtils.bearing(const GeoPoint(0, 0), const GeoPoint(0, 1)), closeTo(90, 0.01));
      expect(GeoUtils.distanceKm(const GeoPoint(0, 0), const GeoPoint(1, 0)), closeTo(111.2, 0.3));
      expect(GeoUtils.lerpAngle(350, 10, 0.5), closeTo(0, 1e-9));
    });

    test('relative angle maps to sides', () {
      expect(SunSide.fromRelative(90, 30), SunSide.right);
      expect(SunSide.fromRelative(270, 30), SunSide.left);
      expect(SunSide.fromRelative(0, 30), SunSide.front);
      expect(SunSide.fromRelative(90, 70), SunSide.top);
      expect(SunSide.fromRelative(90, -5), SunSide.none);
    });
  });

  group('Route sampling', () {
    final sun = const SunRepositoryImpl(SunCalculatorDataSource());

    test('samples once a minute with heading north', () {
      final points = ComputeSunPositions(sun)(
        route: _meridianRoute(12, 13),
        departure: DateTime.utc(2026, 10, 5, 2, 30),
      );
      expect(points.length, 121);
      expect(points.first.bearing, closeTo(0, 0.5));
      expect(points.last.distanceFromStartKm, closeTo(111.2, 0.5));
      final totalWeight = points.fold<double>(0, (a, p) => a + p.weightMinutes);
      expect(totalWeight, closeTo(120, 0.01));
    });

    test('applies vehicle duration factor', () {
      final points = ComputeSunPositions(sun)(
        route: _meridianRoute(12, 13),
        departure: DateTime.utc(2026, 10, 5, 2, 30),
        durationFactor: 1.2,
      );
      expect(points.last.timestamp.difference(points.first.timestamp).inMinutes, 144);
    });
  });

  group('Seat scoring', () {
    final sun = const SunRepositoryImpl(SunCalculatorDataSource());

    test('heading north on a morning: left side wins, right windows are avoided', () {
      final points = ComputeSunPositions(sun)(
        route: _meridianRoute(12, 13),
        departure: DateTime.utc(2026, 10, 5, 2, 30), // 08:00 IST
      );
      final layout = buildBusLayout(DriverPosition.right);
      final stats = JourneyStats.fromPoints(points);
      final scoring = const ComputeSeatScores()(layout, points);
      final recs = const GetSeatRecommendations()(layout, scoring, stats);

      expect(stats.dominantSide, 'right');
      final best = recs.preferences.first;
      expect(best.rank, ZoneRank.first);
      for (final id in best.seatIds) {
        expect(layout.seatById(id)!.side, SeatSide.left, reason: 'best zone seat $id');
      }
      expect(recs.avoid, isNotNull);
      final avoidSeat = layout.seatById(recs.avoid!.seatIds.first)!;
      expect(avoidSeat.side, SeatSide.right);
      expect(avoidSeat.isWindow, isTrue);
      expect(recs.scores.first.overallScore, greaterThan(recs.scores.last.overallScore + 20));
    });

    test('night trip gives full sun protection and ranks on comfort', () {
      final points = ComputeSunPositions(sun)(
        route: _meridianRoute(12, 13),
        departure: DateTime.utc(2026, 10, 5, 17, 30), // 23:00 IST
      );
      final layout = buildCar4Layout(DriverPosition.right);
      final stats = JourneyStats.fromPoints(points);
      final scoring = const ComputeSeatScores()(layout, points);
      expect(stats.isNight, isTrue);
      for (final s in scoring.scores) {
        expect(s.sunProtectionScore, 100);
      }
      final recs = const GetSeatRecommendations()(layout, scoring, stats);
      expect(recs.preferences.first.seatIds.single, 'FP');
      expect(recs.preferences.first.reason, contains('Night journey'));
    });

    test('bus layout has 49 passenger seats plus driver', () {
      final layout = buildBusLayout(DriverPosition.right);
      expect(layout.passengerSeats.length, 49);
      expect(layout.seatMap.where((s) => s.isDriver).length, 1);
    });
  });

  group('Weather', () {
    test('cloud cover and rain reduce sunlight', () {
      WeatherData w(WeatherCondition c, int clouds) => WeatherData(
            condition: c,
            cloudCover: clouds,
            temperature: 25,
            humidity: 50,
            windSpeed: 2,
            icon: '01d',
            description: '',
          );
      expect(w(WeatherCondition.clear, 0).sunlightFactor, 1);
      expect(w(WeatherCondition.cloudy, 50).sunlightFactor, closeTo(0.575, 1e-9));
      expect(w(WeatherCondition.rain, 40).sunlightFactor, lessThanOrEqualTo(0.12));
    });

    test('parses OpenWeather forecast and interpolates', () {
      final f = WeatherForecastModel.fromJson({
        'city': {'name': 'Tumakuru', 'timezone': 19800},
        'list': [
          {
            'dt': 1791136800,
            'main': {'temp': 20, 'humidity': 60},
            'weather': [
              {'id': 800, 'description': 'clear sky', 'icon': '01d'},
            ],
            'clouds': {'all': 0},
            'wind': {'speed': 2},
          },
          {
            'dt': 1791136800 + 3 * 3600,
            'main': {'temp': 30, 'humidity': 40},
            'weather': [
              {'id': 804, 'description': 'overcast clouds', 'icon': '04d'},
            ],
            'clouds': {'all': 100},
            'wind': {'speed': 4},
          },
        ],
      });
      expect(f.placeName, 'Tumakuru');
      final mid = f.at(DateTime.fromMillisecondsSinceEpoch((1791136800 + 5400) * 1000, isUtc: true))!;
      expect(mid.temperature, closeTo(25, 1e-9));
      expect(mid.cloudCover, 50);
      expect(WeatherForecastModel.conditionFor(501, 80), WeatherCondition.rain);
      expect(WeatherForecastModel.conditionFor(802, 40), WeatherCondition.partlyCloudy);
    });
  });
}
