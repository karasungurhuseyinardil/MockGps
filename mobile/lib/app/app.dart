import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_theme.dart';
import '../features/config/app_config.dart';
import '../features/settings/settings_controller.dart';
import '../l10n/gen/app_localizations.dart';
import 'router.dart';
import 'shell.dart';

class MockGpsApp extends ConsumerWidget {
  const MockGpsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);
    final config = ref.watch(appConfigProvider).value;

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        if (config?.updateRequired ?? false) {
          final l = AppLocalizations.of(context);
          return GateScreen(
            icon: Icons.system_update_rounded,
            title: l.updateRequiredTitle,
            body: l.updateRequiredBody,
            action: config!.downloadUrl == null
                ? null
                : FilledButton(
                    onPressed: () => launchUrl(Uri.parse(config.downloadUrl!), mode: LaunchMode.externalApplication),
                    child: Text(l.updateDownload),
                  ),
          );
        }
        return child!;
      },
    );
  }
}

/// Shown when a build was made without the required --dart-define values.
class ConfigMissingApp extends StatelessWidget {
  const ConfigMissingApp({super.key, required this.missing});

  final List<String> missing;

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          final l = AppLocalizations.of(context);
          return GateScreen(icon: Icons.settings_suggest_outlined, title: l.configMissingTitle, body: l.configMissingBody(missing.join(', ')));
        }),
      );
}
