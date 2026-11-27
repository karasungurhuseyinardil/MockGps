import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/geo.dart';
import '../../core/widgets/state_views.dart';
import '../../l10n/gen/app_localizations.dart';
import 'simulation_controller.dart';

String simulationErrorText(AppLocalizations l, String? code) => switch (code) {
      'mock_app_not_selected' => l.simErrorMockApp,
      'foreground_not_allowed' => l.simErrorForeground,
      'invalid_route' => l.simErrorInvalidRoute,
      _ => l.simErrorGeneric,
    };

/// Runs a start action and explains anything that blocks it (permissions, setup).
Future<bool> runSimulationStart(BuildContext context, Future<StartBlocker> Function() start) async {
  final l = AppLocalizations.of(context);
  try {
    final blocker = await start();
    if (!context.mounted) return false;
    switch (blocker) {
      case StartBlocker.none:
        HapticFeedback.mediumImpact();
        return true;
      case StartBlocker.unsupported:
        context.push('/setup');
      case StartBlocker.setupIncomplete:
        showMessage(context, l.mapSetupNeeded);
        context.push('/setup');
      case StartBlocker.permissionDenied:
        showMessage(context, l.setupLocationPermissionHint,
            error: true, action: SnackBarAction(label: l.commonOpenSettings, onPressed: Geolocator.openAppSettings));
    }
  } on PlatformException catch (e) {
    if (context.mounted) showMessage(context, simulationErrorText(l, e.code), error: true);
  }
  return false;
}

Future<bool> startPointSimulation(BuildContext context, WidgetRef ref, GeoPoint point, {String? address, String source = 'map'}) =>
    runSimulationStart(context, () => ref.read(simulationProvider.notifier).startPoint(point, address: address, source: source));
