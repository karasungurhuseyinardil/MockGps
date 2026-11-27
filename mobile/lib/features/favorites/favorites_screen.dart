import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/state_views.dart';
import '../../l10n/gen/app_localizations.dart';
import '../map/map_selection.dart';
import '../simulation/mock_location_channel.dart';
import '../simulation/simulation_actions.dart';
import 'favorite_editor.dart';
import 'favorites_providers.dart';
import 'favorites_repository.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final _search = TextEditingController();
  String? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(favoritesProvider);
    ref.invalidate(categoriesProvider);
    await ref.read(favoritesProvider.future);
  }

  void _showOnMap(Favorite f) {
    ref.read(mapSelectionProvider.notifier).select(
        MapSelection(point: f.point, label: f.name, address: f.address, source: 'favorite', favoriteId: f.id));
    context.go('/');
  }

  Future<void> _activate(Favorite f) async {
    final ok = await startPointSimulation(context, ref, f.point, address: f.address, source: 'favorite');
    if (ok && mounted) _showOnMap(f);
  }

  Future<void> _delete(Favorite f) async {
    final l = AppLocalizations.of(context);
    try {
      await ref.read(favoritesRepositoryProvider).delete(f.id);
      ref.invalidate(favoritesProvider);
      ref.invalidate(categoriesProvider);
      if (!mounted) return;
      showMessage(context, l.favoritesDeleted,
          action: SnackBarAction(
            label: l.commonUndo,
            onPressed: () async {
              await ref.read(favoritesRepositoryProvider).create(FavoriteDraft(
                  name: f.name, description: f.description, point: f.point, address: f.address, categoryId: f.categoryId));
              ref.invalidate(favoritesProvider);
              ref.invalidate(categoriesProvider);
            },
          ));
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final favorites = ref.watch(favoritesProvider);
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    final canSimulate = ref.watch(mockLocationChannelProvider).isSupported;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.favoritesTitle),
        actions: [
          IconButton(tooltip: l.favoritesManageCategories, onPressed: () => context.push('/favorites/categories'), icon: const Icon(Icons.label_outline_rounded)),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.sm),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: l.favoritesSearchHint, prefixIcon: const Icon(Icons.search_rounded)),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.lg),
            children: [
              ChoiceChip(label: Text(l.favoritesAll), selected: _category == null, onSelected: (_) => setState(() => _category = null)),
              for (final c in categories) ...[
                const SizedBox(width: Space.sm),
                ChoiceChip(
                  label: Text('${c.name} · ${c.favoriteCount}'),
                  selected: _category == c.id,
                  onSelected: (v) => setState(() => _category = v ? c.id : null),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: favorites.when(
            loading: () => const SkeletonList(),
            error: (e, _) => ErrorView(error: e, onRetry: _refresh),
            data: (all) {
              if (all.isEmpty) {
                return EmptyView(icon: Icons.star_outline_rounded, title: l.favoritesEmptyTitle, body: l.favoritesEmptyBody);
              }
              final items = filterFavorites(all, query: _search.text, categoryId: _category);
              if (items.isEmpty) return EmptyView(icon: Icons.search_off_rounded, title: l.favoritesNoMatch);
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, Space.xxl),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
                  itemBuilder: (_, i) => _FavoriteTile(
                    favorite: items[i],
                    canSimulate: canSimulate,
                    onActivate: () => _activate(items[i]),
                    onShow: () => _showOnMap(items[i]),
                    onEdit: () => showFavoriteEditor(context, existing: items[i]),
                    onDelete: () => _delete(items[i]),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({required this.favorite, required this.canSimulate, required this.onActivate, required this.onShow, required this.onEdit, required this.onDelete});

  final Favorite favorite;
  final bool canSimulate;
  final VoidCallback onActivate;
  final VoidCallback onShow;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final f = favorite;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: Space.lg, right: Space.xs),
        onTap: onShow,
        title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(f.point.format(5), style: AppTheme.mono(context, size: 12).copyWith(color: c.textMuted)),
          if (f.categoryName != null || f.description != null)
            Text([if (f.categoryName != null) f.categoryName!, if (f.description != null) f.description!].join(' · '),
                maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (canSimulate)
            IconButton(
              tooltip: l.favoritesActivate,
              onPressed: onActivate,
              icon: Icon(Icons.play_circle_fill_rounded, color: c.simulated, size: 32),
            ),
          PopupMenuButton<String>(
            onSelected: (v) => switch (v) { 'show' => onShow(), 'edit' => onEdit(), _ => onDelete() },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'show', child: Text(l.favoritesShowOnMap)),
              PopupMenuItem(value: 'edit', child: Text(l.commonEdit)),
              PopupMenuItem(value: 'delete', child: Text(l.commonDelete)),
            ],
          ),
        ]),
      ),
    );
  }
}

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  Future<String?> _askName(BuildContext context, {String? initial}) {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(initial == null ? l.categoryNew : l.commonEdit),
        content: TextField(controller: controller, autofocus: true, maxLength: 40, decoration: InputDecoration(labelText: l.categoryName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(l.commonSave)),
        ],
      ),
    );
  }

  Future<void> _guard(BuildContext context, WidgetRef ref, Future<void> Function() action) async {
    try {
      await action();
      ref.invalidate(categoriesProvider);
      ref.invalidate(favoritesProvider);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final repo = ref.read(favoritesRepositoryProvider);
    final categories = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.categoriesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final name = await _askName(context);
          if (name != null && name.isNotEmpty && context.mounted) await _guard(context, ref, () => repo.createCategory(name));
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l.categoryNew),
      ),
      body: categories.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(categoriesProvider)),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, 96),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
          itemBuilder: (_, i) {
            final c = items[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(radius: 8, backgroundColor: Color(int.parse('FF${c.color.substring(1)}', radix: 16))),
                title: Text(c.name),
                subtitle: Text(l.categoryCount(c.favoriteCount)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    tooltip: l.commonEdit,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () async {
                      final name = await _askName(context, initial: c.name);
                      if (name != null && name.isNotEmpty && context.mounted) await _guard(context, ref, () => repo.updateCategory(c, name));
                    },
                  ),
                  IconButton(
                    tooltip: l.commonDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          content: Text(l.categoryDeleteConfirm(c.name)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.commonCancel)),
                            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.commonDelete)),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) await _guard(context, ref, () => repo.deleteCategory(c.id));
                    },
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}
