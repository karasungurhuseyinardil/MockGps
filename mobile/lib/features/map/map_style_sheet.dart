import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/state_views.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../config/app_config.dart';
import '../settings/settings_controller.dart';

String mapTypeLabel(AppLocalizations l, String type) => switch (type) {
      'light' => l.mapStyleMinimal,
      'dark' => l.mapStyleDark,
      'satellite' => l.mapStyleSatellite,
      _ => l.mapStyleStandard,
    };

/// Map types available right now. Satellite only appears when the server configured a provider.
List<String> availableMapTypes(AppConfig? config) =>
    ['standard', 'light', 'dark', if (config?.map.satellite != null) 'satellite'];

Future<void> showMapStyleSheet(BuildContext context, WidgetRef ref) => showModalBottomSheet<void>(
      context: context,
      builder: (context) => Consumer(builder: (context, ref, _) {
        final l = AppLocalizations.of(context);
        final current = ref.watch(settingsProvider.select((s) => s.user.defaultMapType));
        final types = availableMapTypes(ref.watch(appConfigProvider).value);
        return SafeArea(
          child: RadioGroup<String>(
            groupValue: current,
            onChanged: (type) async {
              if (type == null) return;
              Navigator.pop(context);
              try {
                await ref.read(settingsProvider.notifier).update((s) => s.copyWith(defaultMapType: type), signedIn: ref.read(isSignedInProvider));
              } catch (e) {
                if (context.mounted) showError(context, e);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.sm),
                  child: Align(alignment: Alignment.centerLeft, child: Text(l.mapLayers, style: context.text.titleMedium)),
                ),
                for (final t in types) RadioListTile<String>(value: t, title: Text(mapTypeLabel(l, t))),
                const SizedBox(height: Space.md),
              ],
            ),
          ),
        );
      }),
    );
