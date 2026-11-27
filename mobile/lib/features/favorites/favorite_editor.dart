import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/geo.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/state_views.dart';
import '../../l10n/gen/app_localizations.dart';
import 'favorites_providers.dart';
import 'favorites_repository.dart';

/// Create or edit a favorite. Returns the saved favorite.
Future<Favorite?> showFavoriteEditor(BuildContext context, {Favorite? existing, GeoPoint? point, String? name, String? address}) =>
    showModalBottomSheet<Favorite>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FavoriteEditor(existing: existing, point: existing?.point ?? point!, name: existing?.name ?? name, address: existing?.address ?? address),
    );

class _FavoriteEditor extends ConsumerStatefulWidget {
  const _FavoriteEditor({this.existing, required this.point, this.name, this.address});

  final Favorite? existing;
  final GeoPoint point;
  final String? name;
  final String? address;

  @override
  ConsumerState<_FavoriteEditor> createState() => _FavoriteEditorState();
}

class _FavoriteEditorState extends ConsumerState<_FavoriteEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.name);
  late final _description = TextEditingController(text: widget.existing?.description);
  late String? _categoryId = widget.existing?.categoryId;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final repo = ref.read(favoritesRepositoryProvider);
    final draft = FavoriteDraft(
      name: _name.text.trim(),
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      point: widget.point,
      address: widget.address,
      categoryId: _categoryId,
    );
    try {
      final saved = widget.existing == null ? await repo.create(draft) : await repo.update(widget.existing!.id, draft);
      ref.invalidate(favoritesProvider);
      ref.invalidate(categoriesProvider);
      if (mounted) Navigator.pop(context, saved);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, MediaQuery.viewInsetsOf(context).bottom + Space.xl),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.favoriteEditTitle, style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: Space.xs),
            Text(widget.point.format(), style: AppTheme.mono(context, size: 13).copyWith(color: context.colors.textMuted)),
            if (widget.address != null)
              Text(widget.address!, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
            const SizedBox(height: Space.lg),
            TextFormField(
              controller: _name,
              autofocus: widget.existing == null,
              maxLength: 80,
              decoration: InputDecoration(labelText: l.favoriteName),
              validator: (v) => (v ?? '').trim().isEmpty ? l.favoriteNameRequired : null,
            ),
            const SizedBox(height: Space.sm),
            TextFormField(
              controller: _description,
              maxLength: 500,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(labelText: l.favoriteDescription, helperText: l.commonOptional),
            ),
            const SizedBox(height: Space.md),
            DropdownButtonFormField<String?>(
              initialValue: categories.any((c) => c.id == _categoryId) ? _categoryId : null,
              decoration: InputDecoration(labelText: l.favoriteCategory),
              items: [
                DropdownMenuItem(value: null, child: Text(l.favoriteNoCategory)),
                for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: Space.xl),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}
