import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/env.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/state_views.dart';
import '../../l10n/gen/app_localizations.dart';
import '../account/account_repository.dart';
import '../auth/auth_controller.dart';
import '../config/app_config.dart';
import '../history/history_repository.dart';
import '../map/map_style_sheet.dart';
import '../simulation/mock_location_channel.dart';
import '../simulation/simulation_controller.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const intervals = [500, 1000, 2000, 5000];

  Future<void> _update(BuildContext context, WidgetRef ref, UserSettings Function(UserSettings) change) async {
    try {
      await ref.read(settingsProvider.notifier).update(change, signedIn: ref.read(isSignedInProvider));
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _setCloudSync(BuildContext context, WidgetRef ref, bool value) async {
    await _update(context, ref, (s) => s.copyWith(historyCloudSync: value));
    final repo = ref.read(historyRepositoryProvider);
    if (!ref.read(settingsProvider).user.historyCloudSync) {
      await repo.markAllUnsynced(); // server removed its copy
    } else {
      unawaited(repo.sync().catchError((_) => 0));
    }
  }

  Future<T?> _pick<T>(BuildContext context, String title, List<(T, String)> options, T current) => showModalBottomSheet<T>(
        context: context,
        builder: (context) => SafeArea(
          child: RadioGroup<T>(
            groupValue: current,
            onChanged: (v) => Navigator.pop(context, v),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(title: Text(title, style: context.text.titleMedium)),
              for (final (value, label) in options) RadioListTile<T>(value: value, title: Text(label)),
            ]),
          ),
        ),
      );

  Future<void> _editName(BuildContext context, WidgetRef ref, Me? me) async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController(text: me?.displayName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.settingsDisplayName),
        content: TextField(controller: controller, autofocus: true, maxLength: 80),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(l.commonSave)),
        ],
      ),
    );
    if (name == null) return;
    try {
      final updated = await ref.read(accountRepositoryProvider).updateDisplayName(name.isEmpty ? null : name);
      ref.read(authProvider.notifier).setMe(updated);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    try {
      final json = await ref.read(accountRepositoryProvider).export();
      final file = File('${(await getTemporaryDirectory()).path}/mockgps-export.json');
      await file.writeAsString(json);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: 'application/json')]));
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l.settingsDeleteConfirmTitle),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.settingsDeleteConfirmBody),
            const SizedBox(height: Space.lg),
            TextField(
              controller: controller,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: l.settingsDeleteConfirmType),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.commonCancel)),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: context.colors.danger),
              onPressed: controller.text.trim().toUpperCase() == l.settingsDeleteConfirmWord ? () => Navigator.pop(context, true) : null,
              child: Text(l.settingsDeleteAccount),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(simulationProvider.notifier).stop();
      await ref.read(accountRepositoryProvider).deleteAccount();
      await ref.read(historyRepositoryProvider).clear(cloud: false);
      await ref.read(authProvider.notifier).signOut();
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final s = settings.user;
    final me = ref.watch(authProvider.select((a) => a.me));
    final version = ref.watch(packageInfoProvider).value;
    final config = ref.watch(appConfigProvider).value;
    final android = ref.watch(mockLocationChannelProvider).isSupported;
    final c = context.colors;

    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(Space.lg, Space.xl, Space.lg, Space.sm),
          child: Text(text, style: context.text.labelLarge?.copyWith(color: c.primary, fontWeight: FontWeight.w600)),
        );

    final themeLabel = switch (s.theme) { 'light' => l.settingsThemeLight, 'dark' => l.settingsThemeDark, _ => l.settingsThemeSystem };

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(padding: const EdgeInsets.only(bottom: Space.xxl), children: [
        header(l.settingsAppearance),
        ListTile(
          leading: const Icon(Icons.brightness_6_outlined),
          title: Text(l.settingsTheme),
          subtitle: Text(themeLabel),
          onTap: () async {
            final v = await _pick(context, l.settingsTheme,
                [('system', l.settingsThemeSystem), ('light', l.settingsThemeLight), ('dark', l.settingsThemeDark)], s.theme);
            if (v != null && context.mounted) await _update(context, ref, (x) => x.copyWith(theme: v));
          },
        ),
        ListTile(
          leading: const Icon(Icons.translate_rounded),
          title: Text(l.settingsLanguage),
          subtitle: Text(s.language == 'tr' ? 'Türkçe' : 'English'),
          onTap: () async {
            final v = await _pick(context, l.settingsLanguage, [('tr', 'Türkçe'), ('en', 'English')], s.language);
            if (v != null && context.mounted) await _update(context, ref, (x) => x.copyWith(language: v));
          },
        ),
        ListTile(
          leading: const Icon(Icons.layers_outlined),
          title: Text(l.settingsDefaultMap),
          subtitle: Text(mapTypeLabel(l, s.defaultMapType)),
          onTap: () => showMapStyleSheet(context, ref),
        ),

        header(l.settingsSimulation),
        ListTile(
          leading: const Icon(Icons.gps_fixed_rounded),
          title: Text(l.settingsAccuracy),
          subtitle: Slider(
            value: s.defaultAccuracyM.clamp(1, 50).toDouble(),
            min: 1,
            max: 50,
            divisions: 49,
            label: l.settingsAccuracyValue(s.defaultAccuracyM),
            onChanged: (v) => ref.read(settingsProvider.notifier).applyServer(s.copyWith(defaultAccuracyM: v.round())),
            onChangeEnd: (v) => _update(context, ref, (x) => x.copyWith(defaultAccuracyM: v.round())),
          ),
          trailing: Text(l.settingsAccuracyValue(s.defaultAccuracyM)),
        ),
        ListTile(
          leading: const Icon(Icons.timer_outlined),
          title: Text(l.settingsInterval),
          subtitle: Text(l.settingsIntervalValue((s.updateIntervalMs / 1000).toString())),
          onTap: () async {
            final v = await _pick(context, l.settingsInterval,
                [for (final i in intervals) (i, l.settingsIntervalValue((i / 1000).toString()))], s.updateIntervalMs);
            if (v != null && context.mounted) await _update(context, ref, (x) => x.copyWith(updateIntervalMs: v));
          },
        ),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.blur_on_rounded),
          title: Text(l.settingsJitter),
          subtitle: Text(l.settingsJitterHint),
          value: settings.jitter,
          onChanged: (v) => ref.read(settingsProvider.notifier).setJitter(v),
        ),
        ListTile(leading: const Icon(Icons.checklist_rounded), title: Text(l.settingsSetupGuide), onTap: () => context.push('/setup')),
        if (android) ListTile(leading: const Icon(Icons.fact_check_outlined), title: Text(l.settingsVerify), onTap: () => context.push('/verify')),

        header(l.settingsPrivacy),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.history_rounded),
          title: Text(l.settingsHistory),
          subtitle: Text(l.settingsHistoryHint),
          value: s.historyEnabled,
          onChanged: (v) => _update(context, ref, (x) => x.copyWith(historyEnabled: v, historyCloudSync: v && x.historyCloudSync)),
        ),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.cloud_sync_outlined),
          title: Text(l.settingsCloudSync),
          subtitle: Text(l.settingsCloudSyncHint),
          value: s.historyCloudSync,
          onChanged: s.historyEnabled ? (v) => _setCloudSync(context, ref, v) : null,
        ),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.campaign_outlined),
          title: Text(l.settingsNotifications),
          subtitle: Text(l.settingsNotificationsHint),
          value: s.notificationsEnabled,
          onChanged: (v) => _update(context, ref, (x) => x.copyWith(notificationsEnabled: v)),
        ),

        header(l.settingsAccount),
        ListTile(
          leading: const Icon(Icons.person_outline_rounded),
          title: Text(me?.displayName ?? l.settingsDisplayName),
          subtitle: Text(me?.email ?? ''),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () => _editName(context, ref, me),
        ),
        ListTile(leading: const Icon(Icons.download_outlined), title: Text(l.settingsExport), onTap: () => _export(context, ref)),
        ListTile(
          leading: const Icon(Icons.logout_rounded),
          title: Text(l.settingsSignOut),
          onTap: () => ref.read(authProvider.notifier).signOut(),
        ),
        ListTile(
          leading: Icon(Icons.delete_forever_outlined, color: c.danger),
          title: Text(l.settingsDeleteAccount, style: TextStyle(color: c.danger)),
          onTap: () => _deleteAccount(context, ref),
        ),

        header(l.settingsAbout),
        ListTile(
          leading: const Icon(Icons.info_outline_rounded),
          title: Text(l.appName),
          subtitle: Text(l.settingsVersion('${version?.version ?? ''} (${version?.buildNumber ?? ''})')),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(l.settingsPrivacyPolicy),
          onTap: () => launchUrl(Uri.parse('${Env.websiteUrl}/privacy'), mode: LaunchMode.externalApplication),
        ),
        ListTile(
          leading: const Icon(Icons.gavel_outlined),
          title: Text(l.settingsTerms),
          onTap: () => launchUrl(Uri.parse('${Env.websiteUrl}/terms'), mode: LaunchMode.externalApplication),
        ),
        if (config?.supportEmail.isNotEmpty ?? false)
          ListTile(
            leading: const Icon(Icons.mail_outline_rounded),
            title: Text(config!.supportEmail),
            onTap: () => launchUrl(Uri(scheme: 'mailto', path: config.supportEmail)),
          ),
      ]),
    );
  }
}
