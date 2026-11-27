import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/geo.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/state_views.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../gpx/gpx.dart';
import '../map/app_map.dart';
import '../simulation/mock_location_channel.dart';
import '../simulation/simulation_actions.dart';
import '../simulation/simulation_controller.dart';
import '../usage/usage_tracker.dart';
import 'routes_repository.dart';

final routesProvider = FutureProvider<List<SavedRoute>>((ref) async {
  if (!ref.watch(isSignedInProvider)) return const [];
  return ref.watch(routesRepositoryProvider).list();
});

Future<void> playRoute(BuildContext context, WidgetRef ref, List<GeoPoint> points, double speedKmh, bool loop) async {
  final l = AppLocalizations.of(context);
  if (!ref.read(mockLocationChannelProvider).isSupported) {
    await Gpx.share(Gpx.route(points, speedKmh: speedKmh, loop: loop), 'mockgps-route');
    ref.read(usageTrackerProvider).track(UsageEvents.gpxExported);
    return;
  }
  final ok = await runSimulationStart(context, () => ref.read(simulationProvider.notifier).startRoute(points, speedKmh: speedKmh, loop: loop));
  if (ok && context.mounted) {
    showMessage(context, l.routeStarted);
    context.go('/');
  }
}

class RoutesScreen extends ConsumerWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final routes = ref.watch(routesProvider);
    final canSimulate = ref.watch(mockLocationChannelProvider).isSupported;
    return Scaffold(
      appBar: AppBar(title: Text(l.routesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/routes/new'),
        icon: const Icon(Icons.add_road_rounded),
        label: Text(l.routesNew),
      ),
      body: routes.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(routesProvider)),
        data: (items) => items.isEmpty
            ? EmptyView(icon: Icons.route_outlined, title: l.routesEmptyTitle, body: l.routesEmptyBody)
            : RefreshIndicator(
                onRefresh: () async => ref.refresh(routesProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
                  itemBuilder: (_, i) {
                    final r = items[i];
                    return Card(
                      child: ListTile(
                        onTap: () => context.push('/routes/${r.id}', extra: r),
                        leading: const Icon(Icons.route_rounded),
                        title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text([
                          l.routePoints(r.points.length),
                          GeoMath.formatDistance(r.distanceMeters),
                          l.routeSpeedValue(r.speedKmh.round()),
                          if (r.loop) l.routeLoop,
                        ].join(' · ')),
                        trailing: IconButton(
                          tooltip: canSimulate ? l.routePlay : l.mapExportGpx,
                          icon: Icon(canSimulate ? Icons.play_circle_fill_rounded : Icons.ios_share_rounded,
                              color: context.colors.simulated, size: 32),
                          onPressed: () => playRoute(context, ref, r.points, r.speedKmh, r.loop),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class RouteEditorScreen extends ConsumerStatefulWidget {
  const RouteEditorScreen({super.key, this.route});

  final SavedRoute? route;

  @override
  ConsumerState<RouteEditorScreen> createState() => _RouteEditorScreenState();
}

class _RouteEditorScreenState extends ConsumerState<RouteEditorScreen> {
  late final _name = TextEditingController(text: widget.route?.name);
  late final List<GeoPoint> _points = [...?widget.route?.points];
  late double _speed = widget.route?.speedKmh ?? 30;
  late bool _loop = widget.route?.loop ?? false;
  MapLibreMapController? _map;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _redraw() async {
    final map = _map;
    if (map == null || !mounted) return;
    final c = context.colors;
    await map.clearLines();
    await map.clearCircles();
    if (_points.length > 1) {
      await map.addLine(LineOptions(
        geometry: [for (final p in [..._points, if (_loop) _points.first]) toLatLng(p)],
        lineColor: hex(c.primary),
        lineWidth: 4,
        lineOpacity: 0.9,
      ));
    }
    for (var i = 0; i < _points.length; i++) {
      await map.addCircle(CircleOptions(
        geometry: toLatLng(_points[i]),
        circleRadius: i == 0 ? 8 : 6,
        circleColor: i == 0 ? hex(c.success) : hex(c.primary),
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2,
      ));
    }
  }

  /// Shows the whole route in the area above the bottom panel.
  Future<void> _fitRoute() async {
    final map = _map;
    if (map == null || _points.length < 2 || !mounted) return;
    var south = _points.first.lat, north = south, west = _points.first.lng, east = west;
    for (final p in _points) {
      south = p.lat < south ? p.lat : south;
      north = p.lat > north ? p.lat : north;
      west = p.lng < west ? p.lng : west;
      east = p.lng > east ? p.lng : east;
    }
    final height = MediaQuery.sizeOf(context).height;
    await map.moveCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(southwest: LatLng(south, west), northeast: LatLng(north, east)),
      left: 48,
      right: 48,
      top: 48,
      bottom: height * 0.55, // panel covers roughly the lower half
    ));
  }

  void _add(GeoPoint p) {
    if (_points.length >= 500) return;
    setState(() => _points.add(p));
    _redraw();
  }

  void _undo() {
    if (_points.isEmpty) return;
    setState(() => _points.removeLast());
    _redraw();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (_points.length < 2) return showMessage(context, l.routeNeedsPoints, error: true);
    final name = _name.text.trim().isEmpty ? '${l.routeEditorTitle} ${DateTime.now().toLocal().toString().substring(0, 16)}' : _name.text.trim();
    setState(() => _busy = true);
    final draft = RouteDraft(name: name, points: _points, speedKmh: _speed, loop: _loop);
    try {
      final repo = ref.read(routesRepositoryProvider);
      widget.route == null ? await repo.create(draft) : await repo.update(widget.route!.id, draft);
      ref.invalidate(routesProvider);
      if (mounted) {
        showMessage(context, l.routeSaved);
        context.pop();
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    try {
      await ref.read(routesRepositoryProvider).delete(widget.route!.id);
      ref.invalidate(routesProvider);
      if (mounted) {
        showMessage(context, l.routeDeleted);
        context.pop();
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final distance = GeoMath.pathMeters(_points, loop: _loop);
    final canSimulate = ref.watch(mockLocationChannelProvider).isSupported;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.route?.name ?? l.routesNew),
        actions: [
          if (widget.route != null) IconButton(tooltip: l.commonDelete, onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded)),
          TextButton(onPressed: _busy ? null : _save, child: Text(l.commonSave)),
        ],
      ),
      body: Stack(children: [
        Positioned.fill(
          child: AppMap(
            initial: _points.isNotEmpty ? _points.first : const GeoPoint(41.0082, 28.9784),
            initialZoom: _points.isNotEmpty ? 13 : 11,
            onReady: (c) {
              _map = c;
              _redraw();
              _fitRoute();
            },
            onTap: _add,
            onLongPress: (_) => _undo(),
          ),
        ),
        Positioned(
          left: Space.md,
          right: Space.md,
          bottom: Space.md,
          child: SafeArea(
            child: GlassPanel(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(l.routeEditorHint, style: context.text.bodySmall?.copyWith(color: context.colors.textMuted)),
                const SizedBox(height: Space.sm),
                TextField(controller: _name, maxLength: 80, decoration: InputDecoration(labelText: l.routeName, counterText: '')),
                const SizedBox(height: Space.sm),
                Row(children: [
                  Text(l.routeSpeed),
                  Expanded(
                    child: Slider(
                      value: _speed,
                      min: 5,
                      max: 200,
                      divisions: 39,
                      label: l.routeSpeedValue(_speed.round()),
                      onChanged: (v) => setState(() => _speed = v),
                    ),
                  ),
                  Text(l.routeSpeedValue(_speed.round())),
                ]),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.routeLoop),
                  subtitle: Text(l.routeLoopHint),
                  value: _loop,
                  onChanged: (v) {
                    setState(() => _loop = v);
                    _redraw();
                  },
                ),
                Row(children: [
                  Text('${l.routePoints(_points.length)} · ${GeoMath.formatDistance(distance)}'),
                  const Spacer(),
                  IconButton(tooltip: l.routeUndoPoint, onPressed: _points.isEmpty ? null : _undo, icon: const Icon(Icons.undo_rounded)),
                  IconButton(
                    tooltip: l.routeClear,
                    onPressed: _points.isEmpty
                        ? null
                        : () {
                            setState(_points.clear);
                            _redraw();
                          },
                    icon: const Icon(Icons.clear_all_rounded),
                  ),
                ]),
                const SizedBox(height: Space.sm),
                FilledButton.icon(
                  onPressed: _points.length < 2 ? null : () => playRoute(context, ref, _points, _speed, _loop),
                  icon: Icon(canSimulate ? Icons.play_arrow_rounded : Icons.ios_share_rounded),
                  label: Text(canSimulate ? l.routePlay : l.mapExportGpx),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
