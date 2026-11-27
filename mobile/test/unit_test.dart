import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockgps/app/router.dart';
import 'package:mockgps/core/geo.dart';
import 'package:mockgps/core/network/api_client.dart';
import 'package:mockgps/features/config/app_config.dart';
import 'package:mockgps/features/favorites/favorites_providers.dart';
import 'package:mockgps/features/favorites/favorites_repository.dart';
import 'package:mockgps/features/gpx/gpx.dart';
import 'package:mockgps/features/history/history_repository.dart';
import 'package:mockgps/features/history/history_screen.dart';
import 'package:mockgps/features/simulation/mock_location_channel.dart';

void main() {
  group('GeoPoint.tryParse', () {
    test('parses common formats', () {
      expect(GeoPoint.tryParse('41.0082, 28.9784'), const GeoPoint(41.0082, 28.9784));
      expect(GeoPoint.tryParse('41.0082 28.9784'), const GeoPoint(41.0082, 28.9784));
      expect(GeoPoint.tryParse('-33.8688;151.2093'), const GeoPoint(-33.8688, 151.2093));
      expect(GeoPoint.tryParse('41,0082; 28,9784'), const GeoPoint(41.0082, 28.9784));
    });

    test('rejects out of range and garbage', () {
      expect(GeoPoint.tryParse('91, 10'), isNull);
      expect(GeoPoint.tryParse('10, 181'), isNull);
      expect(GeoPoint.tryParse('Berlin'), isNull);
      expect(GeoPoint.tryParse('41.0'), isNull);
    });
  });

  test('distance Istanbul → Ankara ≈ 350 km', () {
    final d = GeoMath.distanceMeters(const GeoPoint(41.0082, 28.9784), const GeoPoint(39.9334, 32.8597));
    expect(d, inInclusiveRange(345000, 355000));
  });

  test('loop path adds the closing segment', () {
    const pts = [GeoPoint(0, 0), GeoPoint(0, 1)];
    expect(GeoMath.pathMeters(pts, loop: true), closeTo(2 * GeoMath.pathMeters(pts), 0.001));
  });

  group('GPX', () {
    test('point export is a single waypoint', () {
      final gpx = Gpx.point(const GeoPoint(52.52, 13.405), name: 'A & B');
      expect(gpx, contains('<wpt lat="52.5200000" lon="13.4050000"><name>A &amp; B</name></wpt>'));
      expect(gpx, startsWith('<?xml'));
    });

    test('route export spaces timestamps by travel time', () {
      final gpx = Gpx.route(const [GeoPoint(0, 0), GeoPoint(0, 0.01)], speedKmh: 36, start: DateTime.utc(2026, 1, 1));
      // 0.01° of longitude at the equator ≈ 1112 m → ~111 s at 10 m/s.
      expect(gpx, contains('<time>2026-01-01T00:00:00Z</time>'));
      expect(gpx, contains('<time>2026-01-01T00:01:51Z</time>'));
    });
  });

  test('favorites filter by text and category', () {
    final now = DateTime(2026);
    final items = [
      Favorite(id: '1', name: 'Berlin Mitte', point: const GeoPoint(1, 1), categoryId: 'c', updatedAt: now),
      Favorite(id: '2', name: 'Home', description: 'berlin flat', point: const GeoPoint(1, 1), updatedAt: now),
      Favorite(id: '3', name: 'Office', address: 'Istanbul', point: const GeoPoint(1, 1), categoryId: 'c', updatedAt: now),
    ];
    expect(filterFavorites(items, query: 'BERLIN').map((f) => f.id), ['1', '2']);
    expect(filterFavorites(items, categoryId: 'c').map((f) => f.id), ['1', '3']);
    expect(filterFavorites(items, query: 'istanbul', categoryId: 'c').map((f) => f.id), ['3']);
  });

  test('history groups by local day', () {
    final a = HistoryEntry(id: 'a', point: const GeoPoint(1, 1), source: 'map', createdAt: DateTime(2026, 3, 1, 10), synced: false);
    final b = HistoryEntry(id: 'b', point: const GeoPoint(1, 1), source: 'map', createdAt: DateTime(2026, 3, 1, 8), synced: false);
    final c = HistoryEntry(id: 'c', point: const GeoPoint(1, 1), source: 'map', createdAt: DateTime(2026, 2, 28, 23), synced: false);
    final groups = groupByDay([a, b, c]);
    expect(groups.keys, [DateTime(2026, 3, 1), DateTime(2026, 2, 28)]);
    expect(groups[DateTime(2026, 3, 1)]!.map((e) => e.id), ['a', 'b']);
  });

  group('auth redirect', () {
    test('signed out users go to sign in', () {
      expect(authRedirect(signedIn: false, recovery: false, location: '/'), '/auth/sign-in');
      expect(authRedirect(signedIn: false, recovery: false, location: '/auth/sign-up'), isNull);
    });
    test('signed in users leave auth screens', () {
      expect(authRedirect(signedIn: true, recovery: false, location: '/auth/sign-in'), '/');
      expect(authRedirect(signedIn: true, recovery: false, location: '/favorites'), isNull);
    });
    test('password recovery forces new password screen', () {
      expect(authRedirect(signedIn: true, recovery: true, location: '/'), '/auth/new-password');
      expect(authRedirect(signedIn: true, recovery: true, location: '/auth/new-password'), isNull);
    });
  });

  group('ApiException', () {
    test('maps problem details', () {
      final e = ApiException.fromDio(DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 400, data: {
          'code': 'validation_error',
          'detail': 'One or more fields are invalid.',
          'errors': {'latitude': ['Latitude must be between -90 and 90.']},
        }),
      ));
      expect(e.status, 400);
      expect(e.code, 'validation_error');
      expect(e.fieldErrors['latitude'], ['Latitude must be between -90 and 90.']);
    });
    test('no response is a network error', () {
      final e = ApiException.fromDio(DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionError));
      expect(e.isNetwork, isTrue);
      expect(e.code, 'network');
    });
  });

  test('simulation state is parsed from the platform map', () {
    final s = SimulationState.fromMap({'status': 'running', 'mode': 'route', 'lat': 41.0, 'lng': 29.0, 'progress': 0.5, 'speed': 10.0});
    expect(s.isActive, isTrue);
    expect(s.isRoute, isTrue);
    expect(s.point, const GeoPoint(41, 29));
    expect(SimulationState.fromMap({'status': 'unknown'}).status, SimulationStatus.idle);
  });

  test('setup is ready without optional steps', () {
    final s = SetupStatus.fromMap({
      'locationPermission': true,
      'developerOptionsEnabled': true,
      'mockAppSelected': true,
      'locationEnabled': true,
      'notificationPermission': false,
      'batteryOptimizationIgnored': false,
    });
    expect(s.ready, isTrue);
    expect(SetupStatus.fromMap({'locationPermission': true}).ready, isFalse);
  });

  test('map styles fall back for missing satellite', () {
    expect(MapStyles.fallback.forType('satellite', dark: false), MapStyles.fallback.standard);
    expect(MapStyles.fallback.forType('standard', dark: true), MapStyles.fallback.dark);
    expect(MapStyles.fallback.forType('light', dark: true), MapStyles.fallback.minimal);
  });
}
