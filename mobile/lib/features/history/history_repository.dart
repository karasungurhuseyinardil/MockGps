import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../core/geo.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/local_db.dart';

class HistoryEntry {
  const HistoryEntry({required this.id, required this.point, this.address, required this.source, required this.createdAt, required this.synced});

  final String id;
  final GeoPoint point;
  final String? address;
  final String source;
  final DateTime createdAt;
  final bool synced;

  factory HistoryEntry.fromRow(Map<String, Object?> r) => HistoryEntry(
        id: r['id'] as String,
        point: GeoPoint(r['lat'] as double, r['lng'] as double),
        address: r['address'] as String?,
        source: r['source'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
        synced: (r['synced'] as int) == 1,
      );
}

/// Local-first location history. The device copy is authoritative; when cloud sync is on,
/// unsynced rows are uploaded (idempotent by id) to `/history/batch`.
class HistoryRepository {
  HistoryRepository(this._db, this._api);

  static const maxLocalItems = 1000;
  static const _batchSize = 200;

  final Database _db;
  final ApiClient _api;
  final _uuid = const Uuid();

  Future<List<HistoryEntry>> list({int limit = 500}) async {
    final rows = await _db.query('history', orderBy: 'created_at DESC', limit: limit);
    return rows.map(HistoryEntry.fromRow).toList();
  }

  Future<List<HistoryEntry>> recent({int limit = 5}) async {
    // Distinct places: skip repeats of the same rounded coordinate.
    final rows = await _db.rawQuery('''
      SELECT * FROM history WHERE id IN (
        SELECT id FROM (SELECT id, ROUND(lat, 4) AS rl, ROUND(lng, 4) AS rg, MAX(created_at) AS t
                        FROM history GROUP BY rl, rg ORDER BY t DESC LIMIT ?)
      ) ORDER BY created_at DESC
    ''', [limit]);
    return rows.map(HistoryEntry.fromRow).toList();
  }

  Future<void> add(GeoPoint point, {String? address, required String source}) async {
    await _db.insert('history', {
      'id': _uuid.v4(),
      'lat': point.lat,
      'lng': point.lng,
      'address': address,
      'source': source,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'synced': 0,
    });
    await _db.rawDelete(
        'DELETE FROM history WHERE id NOT IN (SELECT id FROM history ORDER BY created_at DESC LIMIT ?)', [maxLocalItems]);
  }

  Future<void> delete(String id, {required bool cloud}) async {
    await _db.delete('history', where: 'id = ?', whereArgs: [id]);
    if (cloud) await _api.delete<void>('/history/client/$id');
  }

  Future<void> clear({required bool cloud}) async {
    await _db.delete('history');
    if (cloud) await _api.delete<void>('/history');
  }

  /// Marks everything as not uploaded (after cloud sync was turned off, the server copy is gone).
  Future<void> markAllUnsynced() => _db.update('history', {'synced': 0});

  /// Uploads unsynced rows. Safe to call repeatedly.
  Future<int> sync() async {
    var uploaded = 0;
    while (true) {
      final rows = await _db.query('history', where: 'synced = 0', orderBy: 'created_at ASC', limit: _batchSize);
      if (rows.isEmpty) break;
      final items = rows.map(HistoryEntry.fromRow).toList();
      await _api.post<Map<String, dynamic>>('/history/batch', body: {
        'items': [
          for (final e in items)
            {
              'clientId': e.id,
              'latitude': e.point.lat,
              'longitude': e.point.lng,
              'address': e.address,
              'source': e.source,
              'createdAt': e.createdAt.toUtc().toIso8601String(),
            }
        ],
      });
      final batch = _db.batch();
      for (final e in items) {
        batch.update('history', {'synced': 1}, where: 'id = ?', whereArgs: [e.id]);
      }
      await batch.commit(noResult: true);
      uploaded += items.length;
    }
    return uploaded;
  }
}

final historyRepositoryProvider =
    Provider((ref) => HistoryRepository(ref.watch(localDbProvider).db, ref.watch(apiClientProvider)));

/// Bumped whenever local history changes so lists refresh.
final historyRevisionProvider = NotifierProvider<HistoryRevision, int>(HistoryRevision.new);

class HistoryRevision extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final historyListProvider = FutureProvider<List<HistoryEntry>>((ref) {
  ref.watch(historyRevisionProvider);
  return ref.watch(historyRepositoryProvider).list();
});

final recentHistoryProvider = FutureProvider<List<HistoryEntry>>((ref) {
  ref.watch(historyRevisionProvider);
  return ref.watch(historyRepositoryProvider).recent();
});
