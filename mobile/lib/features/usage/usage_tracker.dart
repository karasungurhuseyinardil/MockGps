import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../config/app_config.dart';

/// Batches anonymous usage events (no coordinates) and sends them every 30 seconds.
/// Events are dropped silently on failure; they are statistics, not user data.
class UsageTracker {
  UsageTracker(this._api, this._version);

  final ApiClient _api;
  final String? _version;
  final _queue = <String>[];
  Timer? _timer;
  bool enabled = false;

  void track(String event) {
    if (!enabled) return;
    _queue.add(event);
    _timer ??= Timer(const Duration(seconds: 30), flush);
  }

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_queue.isEmpty || !enabled) return;
    final events = List<String>.of(_queue.take(50));
    _queue.removeRange(0, events.length);
    try {
      await _api.post<dynamic>('/usage-events', body: {
        'platform': Platform.isIOS ? 'ios' : 'android',
        'appVersion': _version,
        'events': events,
      });
    } on ApiException catch (e) {
      debugPrint('Usage events not sent: ${e.code}');
    }
    if (_queue.isNotEmpty) _timer = Timer(const Duration(seconds: 30), flush);
  }

  void dispose() => _timer?.cancel();
}

abstract final class UsageEvents {
  static const simulationStarted = 'simulation_started';
  static const simulationStopped = 'simulation_stopped';
  static const routeStarted = 'route_started';
  static const favoriteActivated = 'favorite_activated';
  static const searchUsed = 'search_used';
  static const gpxExported = 'gpx_exported';
  static const appOpened = 'app_opened';
}

final usageTrackerProvider = Provider<UsageTracker>((ref) {
  final version = ref.watch(packageInfoProvider).value?.version;
  final tracker = UsageTracker(ref.watch(apiClientProvider), version);
  ref.onDispose(tracker.dispose);
  return tracker;
});
