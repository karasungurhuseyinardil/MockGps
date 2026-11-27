import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/state_views.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../map/map_selection.dart';
import '../settings/settings_controller.dart';
import 'history_repository.dart';

/// Groups entries by local calendar day, newest first (pure, unit tested).
Map<DateTime, List<HistoryEntry>> groupByDay(List<HistoryEntry> entries) {
  final groups = <DateTime, List<HistoryEntry>>{};
  for (final e in entries) {
    final local = e.createdAt.toLocal();
    groups.putIfAbsent(DateTime(local.year, local.month, local.day), () => []).add(e);
  }
  return groups;
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  Future<void> _clear(BuildContext context, WidgetRef ref, bool cloud) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l.historyClearConfirm(cloud.toString())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.historyClearAll)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(historyRepositoryProvider).clear(cloud: cloud);
      ref.read(historyRevisionProvider.notifier).bump();
      if (context.mounted) showMessage(context, l.historyCleared);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider).user;
    final cloud = settings.historyCloudSync && ref.watch(isSignedInProvider);
    final history = ref.watch(historyListProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = DateTime.now();
    String dayLabel(DateTime d) {
      final diff = DateTime(today.year, today.month, today.day).difference(d).inDays;
      if (diff == 0) return l.historyToday;
      if (diff == 1) return l.historyYesterday;
      return DateFormat.yMMMMd(locale).format(d);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.historyTitle),
        actions: [
          if ((history.value ?? const []).isNotEmpty)
            TextButton(onPressed: () => _clear(context, ref, cloud), child: Text(l.historyClearAll)),
        ],
      ),
      body: !settings.historyEnabled && (history.value ?? const []).isEmpty
          ? EmptyView(
              icon: Icons.history_toggle_off_rounded,
              title: l.historyDisabledTitle,
              body: l.historyDisabledBody,
              action: OutlinedButton(onPressed: () => context.go('/settings'), child: Text(l.navSettings)),
            )
          : history.when(
              loading: () => const SkeletonList(),
              error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(historyListProvider)),
              data: (entries) {
                if (entries.isEmpty) return EmptyView(icon: Icons.history_rounded, title: l.historyEmptyTitle, body: l.historyEmptyBody);
                final groups = groupByDay(entries);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.xxl),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.sm),
                      child: Row(children: [
                        Icon(cloud ? Icons.cloud_done_outlined : Icons.phone_android_rounded, size: 16, color: context.colors.textMuted),
                        const SizedBox(width: Space.sm),
                        Text(cloud ? l.historySynced : l.historyLocalOnly, style: context.text.bodySmall?.copyWith(color: context.colors.textMuted)),
                      ]),
                    ),
                    for (final day in groups.keys) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: Space.lg, bottom: Space.sm),
                        child: Text(dayLabel(day), style: context.text.labelLarge?.copyWith(color: context.colors.textMuted)),
                      ),
                      for (final e in groups[day]!)
                        Dismissible(
                          key: ValueKey(e.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: Space.xl),
                            color: context.colors.danger,
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                          ),
                          onDismissed: (_) async {
                            try {
                              await ref.read(historyRepositoryProvider).delete(e.id, cloud: cloud && e.synced);
                            } catch (err) {
                              if (context.mounted) showError(context, err);
                            }
                            ref.read(historyRevisionProvider.notifier).bump();
                          },
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(e.source == 'route' ? Icons.route_rounded : Icons.place_outlined),
                            title: Text(e.address?.split(',').take(2).join(',') ?? e.point.format(5), maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${DateFormat.Hm(locale).format(e.createdAt.toLocal())} · ${e.point.format(5)}',
                                style: AppTheme.mono(context, size: 12).copyWith(color: context.colors.textMuted)),
                            trailing: IconButton(
                              tooltip: l.historyUse,
                              icon: const Icon(Icons.north_east_rounded),
                              onPressed: () {
                                ref.read(mapSelectionProvider.notifier).select(MapSelection(point: e.point, address: e.address, source: 'history'));
                                context.go('/');
                              },
                            ),
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
    );
  }
}
