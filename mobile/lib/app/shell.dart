import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/tokens.dart';
import '../l10n/gen/app_localizations.dart';
import '../features/config/app_config.dart';
import '../features/simulation/simulation_controller.dart';

/// Bottom navigation + app-wide banners (maintenance, update available).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final config = ref.watch(appConfigProvider).value;
    final simulating = ref.watch(simulationProvider.select((s) => s.isActive));
    final c = context.colors;

    return Scaffold(
      // Each screen's own Scaffold handles the keyboard; resizing here too would squeeze them twice
      // and hide the keyboard insets from the map screen.
      resizeToAvoidBottomInset: false,
      body: Column(children: [
        if (config?.maintenanceMode ?? false)
          MaterialBanner(
            leading: Icon(Icons.construction_rounded, color: c.warning),
            content: Text('${l.maintenanceTitle}. ${l.maintenanceBody}'),
            actions: const [SizedBox.shrink()],
          )
        else if ((config?.updateAvailable ?? false) && config?.downloadUrl != null)
          MaterialBanner(
            leading: Icon(Icons.system_update_rounded, color: c.primary),
            content: Text(l.updateAvailable),
            actions: [TextButton(onPressed: () => launchUrl(Uri.parse(config!.downloadUrl!), mode: LaunchMode.externalApplication), child: Text(l.updateDownload))],
          ),
        Expanded(child: shell),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: Badge(isLabelVisible: simulating, backgroundColor: c.simulated, smallSize: 8, child: const Icon(Icons.map_outlined)),
            selectedIcon: Badge(isLabelVisible: simulating, backgroundColor: c.simulated, smallSize: 8, child: const Icon(Icons.map_rounded)),
            label: l.navMap,
          ),
          NavigationDestination(icon: const Icon(Icons.star_outline_rounded), selectedIcon: const Icon(Icons.star_rounded), label: l.navFavorites),
          NavigationDestination(icon: const Icon(Icons.route_outlined), selectedIcon: const Icon(Icons.route_rounded), label: l.navRoutes),
          NavigationDestination(icon: const Icon(Icons.history_rounded), label: l.navHistory),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings_rounded), label: l.navSettings),
        ],
      ),
    );
  }
}

class GateScreen extends StatelessWidget {
  const GateScreen({super.key, required this.icon, required this.title, required this.body, this.action});

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(Space.xxl),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 48, color: context.colors.primary),
                const SizedBox(height: Space.lg),
                Text(title, style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                const SizedBox(height: Space.sm),
                Text(body, textAlign: TextAlign.center, style: context.text.bodyMedium?.copyWith(color: context.colors.textMuted)),
                if (action != null) ...[const SizedBox(height: Space.xl), action!],
              ]),
            ),
          ),
        ),
      );
}
