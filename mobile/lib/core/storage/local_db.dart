import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// On-device SQLite database. Location history lives here first (privacy by default).
class LocalDb {
  LocalDb._(this.db);

  final Database db;

  static Future<LocalDb> open({String? path}) async {
    final dbPath = path ?? p.join(await getDatabasesPath(), 'mockgps.db');
    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE history (
            id TEXT PRIMARY KEY,
            lat REAL NOT NULL,
            lng REAL NOT NULL,
            address TEXT,
            source TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('CREATE INDEX history_created_idx ON history (created_at DESC)');
      },
    );
    return LocalDb._(db);
  }
}

/// Overridden in main() after the database is opened.
final localDbProvider = Provider<LocalDb>((ref) => throw UnimplementedError('localDbProvider not initialised'));
