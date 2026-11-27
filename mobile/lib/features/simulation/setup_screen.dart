import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/state_views.dart';
import '../../l10n/gen/app_localizations.dart';
import 'mock_location_channel.dart';
import 'simulation_controller.dart';

/// Step-by-step guide through Android's mock location requirements. Re-checks automatically
/// when the user returns from system settings.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.invalidate(setupStatusProvider);
  }

  Future<void> _requestLocation() async {
    final p = await Geolocator.requestPermission();
    if (p == LocationPermission.deniedForever) await Geolocator.openAppSettings();
    ref.invalidate(setupStatusProvider);
  }

  Future<void> _requestNotifications() async {
    final status = await Permission.notification.request();
    if (status.isPermanentlyDenied) await openAppSettings();
    ref.invalidate(setupStatusProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final channel = ref.watch(mockLocationChannelProvider);
    if (!channel.isSupported) {
      return Scaffold(
        appBar: AppBar(title: Text(l.setupIosTitle)),
        body: EmptyView(icon: Icons.phone_iphone_rounded, title: l.setupIosTitle, body: l.setupIosBody),
      );
    }

    final status = ref.watch(setupStatusProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.setupTitle)),
      body: status.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(setupStatusProvider)),
        data: (s) {
          final st = s!;
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(setupStatusProvider),
            child: ListView(padding: const EdgeInsets.all(Space.lg), children: [
              Text(l.setupIntro, style: context.text.bodyMedium),
              const SizedBox(height: Space.lg),
              _Step(
                n: 1,
                done: st.locationPermission,
                title: l.setupLocationPermission,
                hint: l.setupLocationPermissionHint,
                action: l.setupGrant,
                onAction: _requestLocation,
              ),
              _Step(
                n: 2,
                done: st.locationEnabled,
                title: l.setupLocationOn,
                action: l.setupOpen,
                onAction: () => channel.open('location'),
              ),
              _Step(
                n: 3,
                done: st.developerOptionsEnabled,
                title: l.setupDeveloperOptions,
                hint: l.setupDeveloperOptionsHint,
                action: l.setupOpen,
                onAction: () => channel.open('deviceInfo'),
              ),
              _Step(
                n: 4,
                done: st.mockAppSelected,
                enabled: st.developerOptionsEnabled,
                title: l.setupMockApp,
                hint: l.setupMockAppHint,
                action: l.setupOpen,
                onAction: () => channel.open('developer'),
              ),
              _Step(
                n: 5,
                done: st.notificationPermission,
                optional: true,
                title: l.setupNotificationPermission,
                hint: l.setupNotificationPermissionHint,
                action: l.setupGrant,
                onAction: _requestNotifications,
              ),
              _Step(
                n: 6,
                done: st.batteryOptimizationIgnored,
                optional: true,
                title: l.setupBattery,
                hint: l.setupBatteryHint,
                action: l.setupOpen,
                onAction: () => channel.open('battery'),
              ),
              const SizedBox(height: Space.lg),
              if (st.ready)
                Card(
                  color: context.colors.success.withValues(alpha: 0.12),
                  child: ListTile(
                    leading: Icon(Icons.check_circle_rounded, color: context.colors.success),
                    title: Text(l.setupAllDone),
                  ),
                ),
              const SizedBox(height: Space.lg),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline_rounded, size: 18, color: context.colors.textMuted),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(l.setupDetectionNote, style: context.text.bodySmall?.copyWith(color: context.colors.textMuted))),
              ]),
            ]),
          );
        },
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.n,
    required this.done,
    required this.title,
    this.hint,
    required this.action,
    required this.onAction,
    this.optional = false,
    this.enabled = true,
  });

  final int n;
  final bool done;
  final String title;
  final String? hint;
  final String action;
  final VoidCallback onAction;
  final bool optional;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: done ? c.success : (optional ? c.border : c.primary.withValues(alpha: 0.15)),
            foregroundColor: done ? Colors.white : c.text,
            child: done ? const Icon(Icons.check_rounded) : Text('$n'),
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: enabled ? null : c.textMuted)),
          subtitle: hint == null ? null : Text(hint!),
          trailing: done ? null : TextButton(onPressed: enabled ? onAction : null, child: Text(action)),
        ),
      ),
    );
  }
}
