import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/geo.dart';
import '../../core/network/api_client.dart';

class Place {
  const Place({required this.name, required this.label, required this.point, this.type});

  final String name;
  final String label;
  final GeoPoint point;
  final String? type;

  factory Place.fromJson(Map<String, dynamic> j) => Place(
        name: j['name'] as String,
        label: j['label'] as String,
        point: GeoPoint((j['latitude'] as num).toDouble(), (j['longitude'] as num).toDouble()),
        type: j['type'] as String?,
      );
}

class GeocodingRepository {
  GeocodingRepository(this._api);

  final ApiClient _api;

  Future<List<Place>> search(String query, String lang) async {
    final res = await _api.get<List<dynamic>>('/geocoding/search', query: {'q': query, 'lang': lang, 'limit': 6});
    return res.map((e) => Place.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Null when nothing is found (API returns 204).
  Future<Place?> reverse(GeoPoint p, String lang) async {
    final res = await _api.get<dynamic>('/geocoding/reverse', query: {'lat': p.lat, 'lng': p.lng, 'lang': lang});
    return res is Map<String, dynamic> ? Place.fromJson(res) : null;
  }
}

final geocodingRepositoryProvider = Provider((ref) => GeocodingRepository(ref.watch(apiClientProvider)));
