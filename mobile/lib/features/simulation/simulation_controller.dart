import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/geo.dart';
import '../auth/auth_controller.dart';
import '../history/history_repository.dart';
import '../settings/settings_controller.dart';
import '../usage/usage_tracker.dart';
import 'mock_location_channel.dart';

/// Why a start request did not begin a simulation.
enum StartBlocker { none, unsupported, permissionDenied, setupIncomplete }

class SimulationController extends Notifier<SimulationState> {
  StreamSubscription<SimulationState>? _sub;

  MockLocationChannel get _channel => ref.read(mockLocationChannelProvider);

  @override
  SimulationState build() {
    _sub = _channel.states().listen((s) => state = s);
    ref.onDispose(() => _sub?.cancel());
    return const SimulationState();
  }

  SimulationOptions get _options {
    final s = ref.read(settingsProvider);
    return SimulationOptions(accuracy: s.user.defaultAccuracyM.toDouble(), intervalMs: s.user.updateIntervalMs, jitter: s.jitter);
  }

  /// Requests the runtime permissions and checks Developer options. Returns what is still missing.
  Future<StartBlocker> prepare() async {
    if (!_channel.isSupported) return StartBlocker.unsupported;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return StartBlocker.permissionDenied;
    }
    // Optional: without it the foreground notification is hidden on Android 13+.
    await Permission.notification.request();
    final setup = await _channel.checkSetup();
    return setup.ready ? StartBlocker.none : StartBlocker.setupIncomplete;
  }

  Future<StartBlocker> startPoint(GeoPoint point, {String? address, String source = 'map'}) async {
    final blocker = await prepare();
    if (blocker != StartBlocker.none) return blocker;
    if (state.isActive && !state.isRoute) {
      await _channel.updatePoint(point);
    } else {
      await _channel.startPoint(point, _options);
    }
    ref.read(usageTrackerProvider).track(source == 'favorite' ? UsageEvents.favoriteActivated : UsageEvents.simulationStarted);
    await _recordHistory(point, address: address, source: source);
    return StartBlocker.none;
  }

  Future<StartBlocker> startRoute(List<GeoPoint> points, {required double speedKmh, required bool loop}) async {
    final blocker = await prepare();
    if (blocker != StartBlocker.none) return blocker;
    await _channel.startRoute(points, speedKmh: speedKmh, loop: loop, options: _options);
    ref.read(usageTrackerProvider).track(UsageEvents.routeStarted);
    await _recordHistory(points.first, source: 'route');
    return StartBlocker.none;
  }

  Future<void> pause() => _channel.pause();
  Future<void> resume() => _channel.resume();

  Future<void> stop() async {
    await _channel.stop();
    ref.read(usageTrackerProvider).track(UsageEvents.simulationStopped);
  }

  Future<void> _recordHistory(GeoPoint point, {String? address, required String source}) async {
    final settings = ref.read(settingsProvider).user;
    if (!settings.historyEnabled) return;
    final repo = ref.read(historyRepositoryProvider);
    await repo.add(point, address: address, source: source);
    ref.read(historyRevisionProvider.notifier).bump();
    if (settings.historyCloudSync && ref.read(isSignedInProvider)) {
      unawaited(repo.sync().catchError((_) => 0)); // retried on next start / app launch
    }
  }
}

final simulationProvider = NotifierProvider<SimulationController, SimulationState>(SimulationController.new);

final setupStatusProvider = FutureProvider.autoDispose<SetupStatus?>((ref) async {
  final channel = ref.watch(mockLocationChannelProvider);
  return channel.isSupported ? channel.checkSetup() : null;
});
