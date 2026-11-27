import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/geo.dart';
import '../../core/network/api_client.dart';

class Category {
  const Category({required this.id, required this.name, required this.icon, required this.color, required this.sortOrder, required this.favoriteCount});

  final String id;
  final String name;
  final String icon;
  final String color;
  final int sortOrder;
  final int favoriteCount;

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as String,
        name: j['name'] as String,
        icon: j['icon'] as String,
        color: j['color'] as String,
        sortOrder: j['sortOrder'] as int,
        favoriteCount: j['favoriteCount'] as int,
      );
}

class Favorite {
  const Favorite({
    required this.id,
    required this.name,
    this.description,
    required this.point,
    this.address,
    this.categoryId,
    this.categoryName,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final GeoPoint point;
  final String? address;
  final String? categoryId;
  final String? categoryName;
  final DateTime updatedAt;

  factory Favorite.fromJson(Map<String, dynamic> j) => Favorite(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        point: GeoPoint((j['latitude'] as num).toDouble(), (j['longitude'] as num).toDouble()),
        address: j['address'] as String?,
        categoryId: j['categoryId'] as String?,
        categoryName: j['categoryName'] as String?,
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
}

class FavoriteDraft {
  const FavoriteDraft({required this.name, this.description, required this.point, this.address, this.categoryId});

  final String name;
  final String? description;
  final GeoPoint point;
  final String? address;
  final String? categoryId;

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'latitude': point.lat,
        'longitude': point.lng,
        'address': address,
        'categoryId': categoryId,
      };
}

class FavoritesRepository {
  FavoritesRepository(this._api);

  final ApiClient _api;

  /// Favorites are capped at 1000 per user, so the app loads them in pages of 100.
  Future<List<Favorite>> list({String? search, String? categoryId}) async {
    final all = <Favorite>[];
    var page = 1;
    while (true) {
      final res = await _api.get<Map<String, dynamic>>('/favorites', query: {
        'page': page,
        'pageSize': 100,
        'sort': 'updated_at:desc',
        if (search != null && search.isNotEmpty) 'search': search,
        'categoryId': ?categoryId,
      });
      all.addAll((res['items'] as List).map((e) => Favorite.fromJson(e as Map<String, dynamic>)));
      if (all.length >= (res['totalCount'] as int) || page >= 10) break;
      page++;
    }
    return all;
  }

  Future<Favorite> create(FavoriteDraft d) async => Favorite.fromJson(await _api.post<Map<String, dynamic>>('/favorites', body: d.toJson()));

  Future<Favorite> update(String id, FavoriteDraft d) async =>
      Favorite.fromJson(await _api.put<Map<String, dynamic>>('/favorites/$id', body: d.toJson()));

  Future<void> delete(String id) => _api.delete<void>('/favorites/$id');

  Future<List<Category>> categories() async =>
      (await _api.get<List<dynamic>>('/categories')).map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();

  Future<Category> createCategory(String name, {String? color, String? icon}) async =>
      Category.fromJson(await _api.post<Map<String, dynamic>>('/categories', body: {'name': name, 'color': color, 'icon': icon}));

  Future<Category> updateCategory(Category c, String name) async => Category.fromJson(
      await _api.put<Map<String, dynamic>>('/categories/${c.id}', body: {'name': name, 'color': c.color, 'icon': c.icon, 'sortOrder': c.sortOrder}));

  Future<void> deleteCategory(String id) => _api.delete<void>('/categories/$id');
}

final favoritesRepositoryProvider = Provider((ref) => FavoritesRepository(ref.watch(apiClientProvider)));
