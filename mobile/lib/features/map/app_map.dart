import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/geo.dart';
import '../config/app_config.dart';
import '../settings/settings_controller.dart';

LatLng toLatLng(GeoPoint p) => LatLng(p.lat, p.lng);
GeoPoint toGeo(LatLng p) => GeoPoint(p.latitude, p.longitude);

/// MapLibre map with OpenFreeMap styles chosen from settings + theme.
/// [onReady] is called whenever a style finished loading (annotations must be re-added then).
class AppMap extends ConsumerStatefulWidget {
  const AppMap({
    super.key,
    required this.initial,
    this.initialZoom = 13,
    required this.onReady,
    this.onTap,
    this.onLongPress,
    this.styleOverride,
  });

  final GeoPoint initial;
  final double initialZoom;
  final void Function(MapLibreMapController controller) onReady;
  final void Function(GeoPoint point)? onTap;
  final void Function(GeoPoint point)? onLongPress;
  final String? styleOverride;

  @override
  ConsumerState<AppMap> createState() => _AppMapState();
}

class _AppMapState extends ConsumerState<AppMap> {
  MapLibreMapController? _controller;

  @override
  Widget build(BuildContext context) {
    final styles = ref.watch(appConfigProvider).value?.map ?? MapStyles.fallback;
    final String type = widget.styleOverride ?? ref.watch(settingsProvider).user.defaultMapType;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return MapLibreMap(
      styleString: styles.forType(type, dark: dark),
      initialCameraPosition: CameraPosition(target: toLatLng(widget.initial), zoom: widget.initialZoom),
      onMapCreated: (c) => _controller = c,
      onStyleLoadedCallback: () {
        if (_controller != null) widget.onReady(_controller!);
      },
      onMapClick: widget.onTap == null ? null : (_, latLng) => widget.onTap!(toGeo(latLng)),
      onMapLongClick: widget.onLongPress == null ? null : (_, latLng) => widget.onLongPress!(toGeo(latLng)),
      compassEnabled: true,
      compassViewPosition: CompassViewPosition.topRight,
      compassViewMargins: const Point(16, 120),
      attributionButtonPosition: AttributionButtonPosition.bottomLeft,
      attributionButtonMargins: const Point(8, 8),
      logoEnabled: false,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: false,
      trackCameraPosition: true,
    );
  }
}

String hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
