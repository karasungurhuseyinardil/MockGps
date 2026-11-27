import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/geo.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/state_views.dart';
import '../../l10n/gen/app_localizations.dart';
import 'simulation_controller.dart';

/// Reads the location Android reports to apps (through the same APIs other apps use) and compares
/// it with the simulated point: proof that the simulation really works on this device.
class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key});

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  StreamSubscription<Position>? _sub;
  Position? _position;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _sub = Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.best))
        .listen((p) => setState(() => _position = p), onError: (Object e) => setState(() => _error = e));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final sim = ref.watch(simulationProvider);
    final expected = sim.isActive ? sim.point : null;
    final reported = _position == null ? null : GeoPoint(_position!.latitude, _position!.longitude);
    final distance = expected != null && reported != null ? GeoMath.distanceMeters(expected, reported) : null;
    final ok = distance != null && distance < 50;

    Widget row(String label, String value) => ListTile(
          title: Text(label, style: context.text.labelMedium?.copyWith(color: c.textMuted)),
          subtitle: Text(value, style: AppTheme.mono(context, size: 15)),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l.verifyTitle)),
      body: ListView(padding: const EdgeInsets.all(Space.lg), children: [
        Text(l.verifyBody, style: context.text.bodyMedium),
        const SizedBox(height: Space.lg),
        if (_error != null) ErrorView(error: _error!),
        Card(
          child: Column(children: [
            row(l.verifyExpected, expected?.format() ?? '—'),
            const Divider(),
            row(l.verifyReported, reported?.format() ?? l.verifyWaiting),
            const Divider(),
            row(l.verifyDistance, distance == null ? '—' : GeoMath.formatDistance(distance)),
            const Divider(),
            row(l.verifyMocked, _position == null ? '—' : (_position!.isMocked ? '✓' : '✗')),
          ]),
        ),
        const SizedBox(height: Space.lg),
        if (expected == null)
          Text(l.verifyNotRunning, style: TextStyle(color: c.textMuted))
        else if (distance != null)
          Card(
            color: (ok ? c.success : c.warning).withValues(alpha: 0.12),
            child: ListTile(
              leading: Icon(ok ? Icons.check_circle_rounded : Icons.warning_amber_rounded, color: ok ? c.success : c.warning),
              title: Text(ok ? l.verifyOk : l.verifyMismatch),
            ),
          ),
      ]),
    );
  }
}
