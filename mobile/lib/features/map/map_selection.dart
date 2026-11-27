import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/geo.dart';

/// The point the user picked (map tap, search, coordinates, favorite or history).
class MapSelection {
  const MapSelection({required this.point, this.label, this.address, this.source = 'map', this.favoriteId});

  final GeoPoint point;
  final String? label;
  final String? address;

  /// History source: map | manual | search | favorite | history.
  final String source;
  final String? favoriteId;

  MapSelection withAddress(String? address) =>
      MapSelection(point: point, label: label, address: address, source: source, favoriteId: favoriteId);
}

class MapSelectionController extends Notifier<MapSelection?> {
  @override
  MapSelection? build() => null;

  void select(MapSelection selection) => state = selection;
  void setAddress(GeoPoint point, String? address) {
    if (state?.point == point) state = state!.withAddress(address);
  }

  void clear() => state = null;
}

final mapSelectionProvider = NotifierProvider<MapSelectionController, MapSelection?>(MapSelectionController.new);
