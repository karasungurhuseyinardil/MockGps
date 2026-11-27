// On-device test of the real mock location pipeline (Kotlin service → Android location stack).
// Other apps read locations through the same platform APIs that Geolocator uses here.
//
// Prepare the device once (see docs/android-mock-location.md):
//   adb shell pm grant com.mockgps.mockgps android.permission.ACCESS_FINE_LOCATION
//   adb shell pm grant com.mockgps.mockgps android.permission.POST_NOTIFICATIONS
//   adb shell appops set com.mockgps.mockgps android:mock_location allow
// Run: flutter test integration_test/mock_location_test.dart -d <device>
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockgps/core/geo.dart';
import 'package:mockgps/features/simulation/mock_location_channel.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final channel = MockLocationChannel();

  /// Waits until the system reports a location within [meters] of [target].
  Future<Position> waitForLocation(GeoPoint target, {double meters = 30, Duration timeout = const Duration(seconds: 30)}) async {
    final completer = Completer<Position>();
    final sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 0),
    ).listen((p) {
      if (!completer.isCompleted && GeoMath.distanceMeters(GeoPoint(p.latitude, p.longitude), target) <= meters) {
        completer.complete(p);
      }
    });
    try {
      return await completer.future.timeout(timeout);
    } finally {
      await sub.cancel();
    }
  }

  tearDown(() async => channel.stop());

  testWidgets('device setup is complete', (tester) async {
    final setup = await channel.checkSetup();
    expect(setup.locationPermission, isTrue, reason: 'grant ACCESS_FINE_LOCATION');
    expect(setup.mockAppSelected, isTrue, reason: 'select the app as mock location app');
  });

  testWidgets('point simulation is visible to the platform location APIs', (tester) async {
    const berlin = GeoPoint(52.520008, 13.404954);
    await channel.startPoint(berlin, const SimulationOptions(accuracy: 5, intervalMs: 500));

    final position = await waitForLocation(berlin);
    expect(position.isMocked, isTrue);
    expect(position.accuracy, lessThanOrEqualTo(10));

    final state = await channel.states().firstWhere((s) => s.status == SimulationStatus.running);
    expect(state.mode, 'point');

    // Moving the point while running.
    const paris = GeoPoint(48.856613, 2.352222);
    await channel.updatePoint(paris);
    await waitForLocation(paris);
  });

  testWidgets('route simulation moves along the path', (tester) async {
    const start = GeoPoint(41.0, 29.0);
    const end = GeoPoint(41.0, 29.02); // ~1.7 km east
    await channel.startRoute(const [start, end], speedKmh: 360, loop: false, options: const SimulationOptions(intervalMs: 500));

    await waitForLocation(start, meters: 300);
    final moving = await channel.states().firstWhere((s) => (s.progress ?? 0) > 0.2 && s.speed > 0);
    expect(moving.isRoute, isTrue);
    expect(moving.bearing, closeTo(90, 2));
    await waitForLocation(end, meters: 50, timeout: const Duration(seconds: 40));
  });

  testWidgets('stop returns to idle', (tester) async {
    await channel.startPoint(const GeoPoint(35.6762, 139.6503), const SimulationOptions());
    await channel.states().firstWhere((s) => s.status == SimulationStatus.running);
    await channel.stop();
    final state = await channel.states().firstWhere((s) => s.status == SimulationStatus.idle);
    expect(state.isActive, isFalse);
  });
}
