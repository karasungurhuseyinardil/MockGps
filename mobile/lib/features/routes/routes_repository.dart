import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/geo.dart';
import '../../core/network/api_client.dart';

class SavedRoute {
  const SavedRoute({required this.id, required this.name, required this.points, required this.speedKmh, required this.loop, required this.distanceMeters});

  final String id;
  final String name;
  final List<GeoPoint> points;
  final double speedKmh;
  final bool loop;
  final double distanceMeters;

  factory SavedRoute.fromJson(Map<String, dynamic> j) => SavedRoute(
        id: j['id'] as String,
        name: j['name'] as String,
        points: (j['points'] as List).map((p) => GeoPoint.fromJson(p as Map<String, dynamic>)).toList(),
        speedKmh: (j['speedKmh'] as num).toDouble(),
        loop: j['loop'] as bool,
        distanceMeters: (j['distanceMeters'] as num).toDouble(),
      );
}

class RouteDraft {
  const RouteDraft({required this.name, required this.points, required this.speedKmh, required this.loop});

  final String name;
  final List<GeoPoint> points;
  final double speedKmh;
  final bool loop;

  Map<String, dynamic> toJson() => {
        'name': name,
        'points': points.map((p) => p.toJson()).toList(),
        'speedKmh': speedKmh,
        'loop': loop,
      };
}

class RoutesRepository {
  RoutesRepository(this._api);

  final ApiClient _api;

  Future<List<SavedRoute>> list() async =>
      (await _api.get<List<dynamic>>('/routes')).map((e) => SavedRoute.fromJson(e as Map<String, dynamic>)).toList();

  Future<SavedRoute> create(RouteDraft d) async => SavedRoute.fromJson(await _api.post<Map<String, dynamic>>('/routes', body: d.toJson()));

  Future<SavedRoute> update(String id, RouteDraft d) async =>
      SavedRoute.fromJson(await _api.put<Map<String, dynamic>>('/routes/$id', body: d.toJson()));

  Future<void> delete(String id) => _api.delete<void>('/routes/$id');
}

final routesRepositoryProvider = Provider((ref) => RoutesRepository(ref.watch(apiClientProvider)));
