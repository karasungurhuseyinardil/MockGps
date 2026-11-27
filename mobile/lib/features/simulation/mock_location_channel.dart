import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/geo.dart';

enum SimulationStatus { idle, running, paused, error }

class SimulationState {
  const SimulationState({this.status = SimulationStatus.idle, this.mode, this.point, this.bearing = 0, this.speed = 0, this.progress, this.errorCode});

  final SimulationStatus status;

  /// `point` or `route`.
  final String? mode;
  final GeoPoint? point;
  final double bearing;

  /// Meters per second.
  final double speed;
  final double? progress;
  final String? errorCode;

  bool get isActive => status == SimulationStatus.running || status == SimulationStatus.paused;
  bool get isRoute => mode == 'route';

  factory SimulationState.fromMap(Map<dynamic, dynamic> m) {
    final lat = (m['lat'] as num?)?.toDouble();
    final lng = (m['lng'] as num?)?.toDouble();
    return SimulationState(
      status: SimulationStatus.values.firstWhere((s) => s.name == m['status'], orElse: () => SimulationStatus.idle),
      mode: m['mode'] as String?,
      point: lat != null && lng != null ? GeoPoint(lat, lng) : null,
      bearing: (m['bearing'] as num?)?.toDouble() ?? 0,
      speed: (m['speed'] as num?)?.toDouble() ?? 0,
      progress: (m['progress'] as num?)?.toDouble(),
      errorCode: m['errorCode'] as String?,
    );
  }
}

class SetupStatus {
  const SetupStatus({
    required this.locationPermission,
    required this.notificationPermission,
    required this.developerOptionsEnabled,
    required this.mockAppSelected,
    required this.locationEnabled,
    required this.batteryOptimizationIgnored,
  });

  final bool locationPermission;
  final bool notificationPermission;
  final bool developerOptionsEnabled;
  final bool mockAppSelected;
  final bool locationEnabled;
  final bool batteryOptimizationIgnored;

  /// Battery optimisation is recommended, not required.
  bool get ready => locationPermission && developerOptionsEnabled && mockAppSelected && locationEnabled;

  factory SetupStatus.fromMap(Map<dynamic, dynamic> m) => SetupStatus(
        locationPermission: m['locationPermission'] == true,
        notificationPermission: m['notificationPermission'] == true,
        developerOptionsEnabled: m['developerOptionsEnabled'] == true,
        mockAppSelected: m['mockAppSelected'] == true,
        locationEnabled: m['locationEnabled'] == true,
        batteryOptimizationIgnored: m['batteryOptimizationIgnored'] == true,
      );
}

class SimulationOptions {
  const SimulationOptions({this.accuracy = 5, this.intervalMs = 1000, this.jitter = false});

  final double accuracy;
  final int intervalMs;
  final bool jitter;

  Map<String, dynamic> toMap() => {'accuracy': accuracy, 'intervalMs': intervalMs, 'jitter': jitter};
}

/// Platform bridge to `MockLocationPlugin.kt`. System-wide simulation exists only on Android.
class MockLocationChannel {
  static const _methods = MethodChannel('mockgps/mock_location');
  static const _events = EventChannel('mockgps/mock_location/state');

  bool get isSupported => Platform.isAndroid;

  Stream<SimulationState> states() => isSupported
      ? _events.receiveBroadcastStream().map((e) => SimulationState.fromMap(e as Map))
      : const Stream.empty();

  Future<SetupStatus> checkSetup() async => SetupStatus.fromMap((await _methods.invokeMethod<Map>('checkSetup'))!);

  Future<void> startPoint(GeoPoint p, SimulationOptions o) =>
      _methods.invokeMethod('startPoint', {'lat': p.lat, 'lng': p.lng, ...o.toMap()});

  Future<void> updatePoint(GeoPoint p) => _methods.invokeMethod('updatePoint', {'lat': p.lat, 'lng': p.lng});

  Future<void> startRoute(List<GeoPoint> points, {required double speedKmh, required bool loop, required SimulationOptions options}) =>
      _methods.invokeMethod('startRoute', {
        'points': [for (final p in points) ...[p.lat, p.lng]],
        'speedKmh': speedKmh,
        'loop': loop,
        ...options.toMap(),
      });

  Future<void> pause() => _methods.invokeMethod('pause');
  Future<void> resume() => _methods.invokeMethod('resume');
  Future<void> stop() => _methods.invokeMethod('stop');

  Future<bool> open(String target) async => (await _methods.invokeMethod<bool>(switch (target) {
            'developer' => 'openDeveloperSettings',
            'deviceInfo' => 'openDeviceInfoSettings',
            'location' => 'openLocationSettings',
            'battery' => 'openBatterySettings',
            _ => 'openAppSettings',
          })) ??
      false;
}

final mockLocationChannelProvider = Provider((ref) => MockLocationChannel());
