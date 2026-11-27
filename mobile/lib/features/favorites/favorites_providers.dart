import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'favorites_repository.dart';

/// All favorites of the signed-in user (≤ 1000). Filtering for the UI happens locally so search
/// is instant; the API search parameter is available for other clients.
final favoritesProvider = FutureProvider<List<Favorite>>((ref) async {
  if (!ref.watch(isSignedInProvider)) return const [];
  return ref.watch(favoritesRepositoryProvider).list();
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  if (!ref.watch(isSignedInProvider)) return const [];
  return ref.watch(favoritesRepositoryProvider).categories();
});

/// Pure filter used by the list screen (unit tested).
List<Favorite> filterFavorites(List<Favorite> all, {String query = '', String? categoryId}) {
  final q = query.trim().toLowerCase();
  return all.where((f) {
    if (categoryId != null && f.categoryId != categoryId) return false;
    if (q.isEmpty) return true;
    return f.name.toLowerCase().contains(q) ||
        (f.description?.toLowerCase().contains(q) ?? false) ||
        (f.address?.toLowerCase().contains(q) ?? false);
  }).toList();
}
