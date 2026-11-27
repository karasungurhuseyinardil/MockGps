import 'package:flutter/material.dart';

import '../../core/geo.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../simulation/mock_location_channel.dart';

class QuickPlace {
  const QuickPlace({required this.label, required this.point, required this.icon, this.address, this.favoriteId});

  final String label;
  final GeoPoint point;
  final IconData icon;
  final String? address;
  final String? favoriteId;
}

/// Bottom glass panel of the map screen. Pure UI (no providers) so it is widget tested.
class LocationPanel extends StatelessWidget {
  const LocationPanel({
    super.key,
    required this.selected,
    required this.address,
    required this.addressLoading,
    required this.simulation,
    required this.canSimulate,
    required this.quickPlaces,
    required this.onStart,
    required this.onStop,
    required this.onPause,
    required this.onResume,
    required this.onSave,
    required this.onCoordinates,
    required this.onCopy,
    required this.onExportGpx,
    required this.onQuickPlace,
    this.busy = false,
  });

  final GeoPoint? selected;
  final String? address;
  final bool addressLoading;
  final SimulationState simulation;

  /// False on iOS: system-wide simulation is not possible there.
  final bool canSimulate;
  final List<QuickPlace> quickPlaces;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback? onSave;
  final VoidCallback onCoordinates;
  final VoidCallback onCopy;
  final VoidCallback onExportGpx;
  final void Function(QuickPlace place) onQuickPlace;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final active = simulation.isActive;
    final sameAsSimulated = active && selected != null && simulation.point != null &&
        GeoMath.distanceMeters(selected!, simulation.point!) < 1;

    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, Space.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selected == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.sm),
              child: Row(children: [
                Icon(Icons.touch_app_outlined, color: c.textMuted),
                const SizedBox(width: Space.md),
                Expanded(child: Text(l.mapTapToSelect, style: context.text.bodyMedium?.copyWith(color: c.textMuted))),
                IconButton(tooltip: l.mapEnterCoordinates, onPressed: onCoordinates, icon: const Icon(Icons.edit_location_alt_outlined)),
              ]),
            )
          else ...[
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.mapSelectedLocation, style: context.text.labelSmall?.copyWith(color: c.textMuted)),
                  const SizedBox(height: 2),
                  Semantics(
                    label: '${l.coordsLatitude} ${selected!.lat.toStringAsFixed(6)}, ${l.coordsLongitude} ${selected!.lng.toStringAsFixed(6)}',
                    child: ExcludeSemantics(child: Text(selected!.format(), style: AppTheme.mono(context, size: 15))),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    addressLoading ? l.mapLookingUpAddress : (address ?? l.mapNoAddress),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(color: c.textMuted),
                  ),
                ]),
              ),
              IconButton(tooltip: l.mapCopyCoordinates, onPressed: onCopy, icon: const Icon(Icons.copy_rounded, size: 20)),
              IconButton(tooltip: l.mapEnterCoordinates, onPressed: onCoordinates, icon: const Icon(Icons.edit_location_alt_outlined)),
              if (onSave != null) IconButton(tooltip: l.mapSaveFavorite, onPressed: onSave, icon: const Icon(Icons.star_border_rounded)),
            ]),
            const SizedBox(height: Space.md),
          ],
          if (quickPlaces.isNotEmpty && !active) ...[
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: quickPlaces.length,
                separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
                itemBuilder: (_, i) {
                  final p = quickPlaces[i];
                  return ActionChip(avatar: Icon(p.icon, size: 18), label: Text(p.label), onPressed: () => onQuickPlace(p));
                },
              ),
            ),
            const SizedBox(height: Space.md),
          ],
          _actions(context, l, c, active, sameAsSimulated),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, AppLocalizations l, AppColors c, bool active, bool sameAsSimulated) {
    if (!canSimulate) {
      return FilledButton.icon(
        onPressed: selected == null ? null : onExportGpx,
        icon: const Icon(Icons.ios_share_rounded),
        label: Text(l.mapExportGpx),
      );
    }
    final stop = FilledButton.icon(
      style: FilledButton.styleFrom(backgroundColor: c.simulated, foregroundColor: Colors.white),
      onPressed: busy ? null : onStop,
      icon: const Icon(Icons.stop_rounded),
      label: Text(l.mapStop),
    );
    if (!active) {
      return FilledButton.icon(
        onPressed: selected == null || busy ? null : onStart,
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(l.mapStart),
      );
    }
    return Row(children: [
      if (simulation.isRoute)
        Expanded(
          child: OutlinedButton.icon(
            onPressed: busy ? null : (simulation.status == SimulationStatus.paused ? onResume : onPause),
            icon: Icon(simulation.status == SimulationStatus.paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
            label: Text(simulation.status == SimulationStatus.paused ? l.mapResume : l.mapPause),
          ),
        )
      else if (selected != null && !sameAsSimulated)
        Expanded(
          child: OutlinedButton.icon(onPressed: busy ? null : onStart, icon: const Icon(Icons.near_me_rounded), label: Text(l.mapUpdate)),
        ),
      if (simulation.isRoute || (selected != null && !sameAsSimulated)) const SizedBox(width: Space.md),
      Expanded(child: stop),
    ]);
  }
}
