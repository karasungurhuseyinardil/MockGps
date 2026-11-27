import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/errors.dart';
import '../../core/geo.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/state_views.dart';
import '../../l10n/gen/app_localizations.dart';
import '../config/app_config.dart';
import '../favorites/favorite_editor.dart';
import '../favorites/favorites_providers.dart';
import '../geocoding/geocoding_repository.dart';
import '../gpx/gpx.dart';
import '../history/history_repository.dart';
import '../settings/settings_controller.dart';
import '../simulation/mock_location_channel.dart';
import '../simulation/simulation_actions.dart';
import '../simulation/simulation_controller.dart';
import '../usage/usage_tracker.dart';
import 'app_map.dart';
import 'coordinates_dialog.dart';
import 'location_panel.dart';
import 'map_selection.dart';
import 'map_style_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  static const _defaultCenter = GeoPoint(41.0082, 28.9784);

  MapLibreMapController? _map;
  Circle? _halo;
  Timer? _pulse;
  int _pulseStep = 0;
  bool _busy = false;
  bool _addressLoading = false;
  int _addressRequest = 0;

  @override
  void dispose() {
    _pulse?.cancel();
    super.dispose();
  }

  // --- Map annotations -------------------------------------------------------------------------

  GeoPoint? _mapCenter() {
    final target = _map?.cameraPosition?.target;
    return target == null ? null : GeoPoint(target.latitude, target.longitude);
  }

  Future<void> _onMapReady(MapLibreMapController controller) async {
    _map = controller;
    await _syncAnnotations();
    final selection = ref.read(mapSelectionProvider);
    final sim = ref.read(simulationProvider);
    final focus = selection?.point ?? sim.point;
    if (focus != null) await controller.moveCamera(CameraUpdate.newLatLng(toLatLng(focus)));
  }

  Future<void> _syncAnnotations() async {
    final map = _map;
    if (map == null || !mounted) return;
    final c = context.colors;
    final selection = ref.read(mapSelectionProvider);
    final sim = ref.read(simulationProvider);
    _pulse?.cancel();
    _halo = null;
    await map.clearCircles();

    final simPoint = sim.isActive ? sim.point : null;
    if (simPoint != null) {
      _halo = await map.addCircle(CircleOptions(
        geometry: toLatLng(simPoint), circleRadius: 18, circleColor: hex(c.simulated), circleOpacity: 0.25));
      await map.addCircle(CircleOptions(
        geometry: toLatLng(simPoint), circleRadius: 9, circleColor: hex(c.simulated), circleStrokeColor: '#FFFFFF', circleStrokeWidth: 3));
      if (mounted && !MediaQuery.disableAnimationsOf(context)) {
        _pulse = Timer.periodic(const Duration(milliseconds: 90), (_) => _animatePulse(simPoint));
      }
    }
    if (selection != null && (simPoint == null || GeoMath.distanceMeters(selection.point, simPoint) > 1)) {
      await map.addCircle(CircleOptions(
        geometry: toLatLng(selection.point), circleRadius: 8, circleColor: hex(c.primary), circleStrokeColor: '#FFFFFF', circleStrokeWidth: 3));
    }
  }

  void _animatePulse(GeoPoint p) {
    final halo = _halo;
    final map = _map;
    if (halo == null || map == null) return;
    _pulseStep = (_pulseStep + 1) % 24;
    final t = _pulseStep / 24;
    map.updateCircle(halo, CircleOptions(geometry: toLatLng(p), circleRadius: 12 + 20 * t, circleOpacity: 0.35 * (1 - t)));
  }

  // --- Selection ------------------------------------------------------------------------------

  void _select(GeoPoint point, {String? label, String? address, String source = 'map', String? favoriteId, bool move = false}) {
    ref.read(mapSelectionProvider.notifier).select(MapSelection(point: point, label: label, address: address, source: source, favoriteId: favoriteId));
    if (move) _map?.animateCamera(CameraUpdate.newLatLngZoom(toLatLng(point), 15));
    if (address == null) _lookupAddress(point);
  }

  Future<void> _lookupAddress(GeoPoint point) async {
    final request = ++_addressRequest;
    setState(() => _addressLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 350)); // debounce quick taps
    if (request != _addressRequest) return;
    try {
      final lang = ref.read(settingsProvider).user.language;
      final place = await ref.read(geocodingRepositoryProvider).reverse(point, lang);
      if (request == _addressRequest) ref.read(mapSelectionProvider.notifier).setAddress(point, place?.label);
    } catch (_) {
      // Address is optional; the coordinates are what matters.
    } finally {
      if (mounted && request == _addressRequest) setState(() => _addressLoading = false);
    }
  }

  Future<void> _goToMyLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(timeLimit: Duration(seconds: 10)));
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 15));
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  // --- Actions --------------------------------------------------------------------------------

  Future<void> _start() async {
    final selection = ref.read(mapSelectionProvider);
    if (selection == null) return;
    setState(() => _busy = true);
    final ok = await startPointSimulation(context, ref, selection.point, address: selection.address, source: selection.source);
    if (mounted) {
      setState(() => _busy = false);
      if (ok) showMessage(context, AppLocalizations.of(context).mapSimulationStarted);
    }
  }

  Future<void> _stop() async {
    setState(() => _busy = true);
    try {
      await ref.read(simulationProvider.notifier).stop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enterCoordinates() async {
    final p = await showCoordinatesDialog(context, initial: ref.read(mapSelectionProvider)?.point);
    if (p != null) _select(p, source: 'manual', move: true);
  }

  Future<void> _save() async {
    final s = ref.read(mapSelectionProvider);
    if (s == null) return;
    final saved = await showFavoriteEditor(context, point: s.point, name: s.label ?? s.address?.split(',').first, address: s.address);
    if (saved != null && mounted) showMessage(context, AppLocalizations.of(context).favoritesSaved);
  }

  Future<void> _exportGpx() async {
    final s = ref.read(mapSelectionProvider);
    if (s == null) return;
    await Gpx.share(Gpx.point(s.point, name: s.label ?? 'Mock GPS'), 'mockgps-${s.point.lat.toStringAsFixed(4)}_${s.point.lng.toStringAsFixed(4)}');
    ref.read(usageTrackerProvider).track(UsageEvents.gpxExported);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final selection = ref.watch(mapSelectionProvider);
    final sim = ref.watch(simulationProvider);
    final favorites = ref.watch(favoritesProvider).value ?? const [];
    final recents = ref.watch(recentHistoryProvider).value ?? const [];
    final canSimulate = ref.watch(mockLocationChannelProvider).isSupported;
    // Rebuilds when the keyboard opens/closes; the panel would not fit above it.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    ref.listen(mapSelectionProvider, (_, _) => _syncAnnotations());
    ref.listen(simulationProvider, (prev, next) {
      if (prev?.status != next.status || prev?.point != next.point) _syncAnnotations();
      if (next.status == SimulationStatus.error && prev?.status != SimulationStatus.error) {
        showMessage(context, simulationErrorText(l, next.errorCode), error: true);
      }
    });
    ref.listen(settingsProvider.select((s) => s.user.defaultMapType), (_, _) => _halo = null);

    final quick = <QuickPlace>[
      for (final f in favorites.take(6)) QuickPlace(label: f.name, point: f.point, icon: Icons.star_rounded, address: f.address, favoriteId: f.id),
      for (final h in recents.take(3))
        QuickPlace(label: h.address?.split(',').first ?? h.point.format(3), point: h.point, icon: Icons.history_rounded, address: h.address),
    ];

    return Scaffold(
      // The keyboard covers the bottom panel instead of squeezing the overlay column.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: AppMap(
              initial: selection?.point ?? sim.point ?? _defaultCenter,
              initialZoom: selection != null || sim.point != null ? 14 : 11,
              onReady: _onMapReady,
              onTap: (p) {
                FocusScope.of(context).unfocus();
                _select(p);
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                children: [
                  _SearchBox(near: _mapCenter, onSelected: (place) {
                    ref.read(usageTrackerProvider).track(UsageEvents.searchUsed);
                    _select(place.point, label: place.name, address: place.label, source: 'search', move: true);
                  }),
                  if (sim.isActive) ...[
                    const SizedBox(height: Space.sm),
                    _StatusPill(state: sim, onTap: () => _map?.animateCamera(CameraUpdate.newLatLng(toLatLng(sim.point!)))),
                  ],
                  if (!keyboardOpen) const _AnnouncementBanner(),
                  const Spacer(),
                  if (!keyboardOpen) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      GlassIconButton(icon: Icons.layers_outlined, tooltip: l.mapLayers, onPressed: () => showMapStyleSheet(context, ref)),
                      const SizedBox(height: Space.sm),
                      GlassIconButton(icon: Icons.my_location_rounded, tooltip: l.mapMyLocation, onPressed: _goToMyLocation),
                    ]),
                  ),
                  const SizedBox(height: Space.md),
                  LocationPanel(
                    selected: selection?.point,
                    address: selection?.address,
                    addressLoading: _addressLoading && selection?.address == null,
                    simulation: sim,
                    canSimulate: canSimulate,
                    quickPlaces: quick,
                    busy: _busy,
                    onStart: _start,
                    onStop: _stop,
                    onPause: () => ref.read(simulationProvider.notifier).pause(),
                    onResume: () => ref.read(simulationProvider.notifier).resume(),
                    onSave: selection == null || selection.favoriteId != null ? null : _save,
                    onCoordinates: _enterCoordinates,
                    onCopy: () {
                      Clipboard.setData(ClipboardData(text: selection!.point.format()));
                      showMessage(context, l.mapCopied);
                    },
                    onExportGpx: _exportGpx,
                    onQuickPlace: (p) => _select(p.point,
                        label: p.label, address: p.address, source: p.favoriteId != null ? 'favorite' : 'history', favoriteId: p.favoriteId, move: true),
                  ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.state, required this.onTap});

  final SimulationState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final paused = state.status == SimulationStatus.paused;
    final label = state.isRoute && state.progress != null
        ? '${paused ? l.mapPaused : l.mapSimulating} · ${l.mapRouteProgress((state.progress! * 100).round())}'
        : (paused ? l.mapPaused : l.mapSimulating);
    return Semantics(
      liveRegion: true,
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
          decoration: BoxDecoration(color: c.simulated, borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(paused ? Icons.pause_circle_filled_rounded : Icons.sensors_rounded, size: 18, color: Colors.white),
            const SizedBox(width: Space.sm),
            Text(label, style: context.text.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
            if (state.point != null) ...[
              const SizedBox(width: Space.sm),
              Text(state.point!.format(4), style: AppTheme.mono(context, size: 12).copyWith(color: Colors.white)),
            ],
          ]),
        ),
      ),
    );
  }
}

class _SearchBox extends ConsumerStatefulWidget {
  const _SearchBox({required this.onSelected, required this.near});

  final void Function(Place place) onSelected;

  /// Current map centre, used to rank nearby results first.
  final GeoPoint? Function() near;

  @override
  ConsumerState<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends ConsumerState<_SearchBox> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  List<Place> _results = const [];
  bool _loading = false;
  Object? _error;
  int _request = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    if (text.trim().length < 2) {
      setState(() => _results = const []);
      return;
    }
    // Coordinates typed into search go straight to the map.
    final coords = GeoPoint.tryParse(text);
    if (coords != null) {
      setState(() => _results = [Place(name: coords.format(), label: AppLocalizations.of(context).mapEnterCoordinates, point: coords)]);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(text.trim()));
  }

  Future<void> _search(String q) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await ref.read(geocodingRepositoryProvider).search(q, ref.read(settingsProvider).user.language, near: widget.near());
      if (mounted && request == _request) setState(() => _results = results);
    } catch (e) {
      if (mounted && request == _request) setState(() => _error = e);
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final showResults = _focus.hasFocus && _controller.text.trim().length >= 2;
    final enabled = ref.watch(appConfigProvider).value?.geocodingEnabled ?? true;

    return GlassPanel(
      padding: EdgeInsets.zero,
      radius: Radii.lg,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: _controller,
          focusNode: _focus,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          onTap: () => setState(() {}),
          decoration: InputDecoration(
            hintText: enabled ? l.mapSearchHint : l.errorGeocodingDisabled,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _loading
                ? const Padding(padding: EdgeInsets.all(14), child: SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                : _controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l.commonClose,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() {
                          _controller.clear();
                          _results = const [];
                          _focus.unfocus();
                        }),
                      ),
          ),
        ),
        if (showResults) ...[
          Divider(height: 1, color: c.border),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: _error != null
                ? Padding(padding: const EdgeInsets.all(Space.lg), child: Text(describeError(l, _error!)))
                : _results.isEmpty && !_loading
                    ? Padding(padding: const EdgeInsets.all(Space.lg), child: Text(l.mapNoResults, style: TextStyle(color: c.textMuted)))
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _results.length,
                        itemBuilder: (_, i) {
                          final p = _results[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.place_outlined),
                            title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(p.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                            onTap: () {
                              _focus.unfocus();
                              setState(() => _results = const []);
                              _controller.text = p.name;
                              widget.onSelected(p);
                            },
                          );
                        },
                      ),
          ),
        ],
      ]),
    );
  }
}

class _AnnouncementBanner extends ConsumerStatefulWidget {
  const _AnnouncementBanner();

  @override
  ConsumerState<_AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends ConsumerState<_AnnouncementBanner> {
  static const _key = 'announcements.dismissed';

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(sharedPreferencesProvider);
    final enabled = ref.watch(settingsProvider.select((s) => s.user.notificationsEnabled));
    final dismissed = prefs.getStringList(_key) ?? const [];
    final items = ref.watch(appConfigProvider).value?.announcements ?? const [];
    final visible = items.where((a) => !dismissed.contains(a.id) && (enabled || a.level == 'critical')).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    final a = visible.first;
    final c = context.colors;
    final color = switch (a.level) { 'critical' => c.danger, 'warning' => c.warning, _ => c.primary };

    return Padding(
      padding: const EdgeInsets.only(top: Space.sm),
      child: GlassPanel(
        radius: Radii.lg,
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.xs, Space.md),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.campaign_rounded, color: color),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.title, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              Text(a.body, style: context.text.bodySmall),
            ]),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).commonClose,
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () async {
              await prefs.setStringList(_key, [...dismissed, a.id]);
              setState(() {});
            },
          ),
        ]),
      ),
    );
  }
}
