import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockgps/core/geo.dart';
import 'package:mockgps/core/network/api_client.dart';
import 'package:mockgps/core/storage/local_db.dart';
import 'package:mockgps/features/history/history_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Records requests instead of calling the network.
class _RecordingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return ResponseBody.fromString('{"received":1,"inserted":1}', 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late LocalDb db;
  late HistoryRepository repo;
  late _RecordingAdapter adapter;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await LocalDb.open(path: inMemoryDatabasePath);
    adapter = _RecordingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1'))..httpClientAdapter = adapter;
    repo = HistoryRepository(db.db, ApiClient(dio));
  });

  tearDown(() => db.db.close());

  test('adds and lists newest first', () async {
    await repo.add(const GeoPoint(1, 1), source: 'map');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.add(const GeoPoint(2, 2), source: 'search');
    final items = await repo.list();
    expect(items.map((e) => e.point.lat), [2, 1]);
    expect(items.first.synced, isFalse);
  });

  test('recent deduplicates the same place', () async {
    await repo.add(const GeoPoint(41.00821, 28.97841), source: 'map');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.add(const GeoPoint(41.00822, 28.97842), source: 'map');
    await repo.add(const GeoPoint(52.52, 13.405), source: 'map');
    expect((await repo.recent()).length, 2);
  });

  test('sync uploads unsynced rows once and marks them', () async {
    await repo.add(const GeoPoint(1, 1), source: 'map');
    await repo.add(const GeoPoint(2, 2), source: 'map');
    expect(await repo.sync(), 2);
    expect(adapter.requests.single.path, '/history/batch');
    final body = adapter.requests.single.data as Map<String, dynamic>;
    expect((body['items'] as List).length, 2);
    expect(await repo.sync(), 0);
    expect((await repo.list()).every((e) => e.synced), isTrue);

    await repo.markAllUnsynced();
    expect((await repo.list()).every((e) => !e.synced), isTrue);
  });

  test('delete with cloud calls the client-id endpoint', () async {
    await repo.add(const GeoPoint(1, 1), source: 'map');
    final id = (await repo.list()).single.id;
    await repo.delete(id, cloud: true);
    expect(await repo.list(), isEmpty);
    expect(adapter.requests.single.path, '/history/client/$id');
    expect(adapter.requests.single.method, 'DELETE');
  });

  test('clear local only does not call the API', () async {
    await repo.add(const GeoPoint(1, 1), source: 'map');
    await repo.clear(cloud: false);
    expect(await repo.list(), isEmpty);
    expect(adapter.requests, isEmpty);
  });
}
