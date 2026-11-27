import 'package:flutter/material.dart';

import '../../core/geo.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/gen/app_localizations.dart';

/// Manual latitude/longitude entry. Pasting "lat, lng" into either field fills both.
Future<GeoPoint?> showCoordinatesDialog(BuildContext context, {GeoPoint? initial}) =>
    showModalBottomSheet<GeoPoint>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CoordinatesSheet(initial: initial),
    );

class _CoordinatesSheet extends StatefulWidget {
  const _CoordinatesSheet({this.initial});

  final GeoPoint? initial;

  @override
  State<_CoordinatesSheet> createState() => _CoordinatesSheetState();
}

class _CoordinatesSheetState extends State<_CoordinatesSheet> {
  final _form = GlobalKey<FormState>();
  late final _lat = TextEditingController(text: widget.initial?.lat.toStringAsFixed(6));
  late final _lng = TextEditingController(text: widget.initial?.lng.toStringAsFixed(6));

  @override
  void dispose() {
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  static double? parse(String? s) => double.tryParse((s ?? '').trim().replaceAll(',', '.'));

  void _onChanged(String value) {
    final pair = GeoPoint.tryParse(value);
    if (pair != null && value.contains(RegExp(r'[,; ]\s*-?\d'))) {
      _lat.text = pair.lat.toString();
      _lng.text = pair.lng.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mono = AppTheme.mono(context, size: 16);
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, MediaQuery.viewInsetsOf(context).bottom + Space.xl),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.coordsTitle, style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: Space.sm),
            Text(l.coordsPasteHint, style: context.text.bodySmall?.copyWith(color: context.colors.textMuted)),
            const SizedBox(height: Space.lg),
            TextFormField(
              controller: _lat,
              autofocus: true,
              style: mono,
              decoration: InputDecoration(labelText: l.coordsLatitude, hintText: '41.008200'),
              keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
              onChanged: _onChanged,
              validator: (v) {
                final n = parse(v);
                return n == null || n < -90 || n > 90 ? l.coordsInvalidLat : null;
              },
            ),
            const SizedBox(height: Space.md),
            TextFormField(
              controller: _lng,
              style: mono,
              decoration: InputDecoration(labelText: l.coordsLongitude, hintText: '28.978400'),
              keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
              onChanged: _onChanged,
              validator: (v) {
                final n = parse(v);
                return n == null || n < -180 || n > 180 ? l.coordsInvalidLng : null;
              },
            ),
            const SizedBox(height: Space.xl),
            FilledButton(
              onPressed: () {
                if (!_form.currentState!.validate()) return;
                Navigator.pop(context, GeoPoint(parse(_lat.text)!, parse(_lng.text)!));
              },
              child: Text(l.coordsGo),
            ),
          ],
        ),
      ),
    );
  }
}
