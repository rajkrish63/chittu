import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'schema.dart';

class DatabaseHelper {
  DatabaseHelper._private();
  static final DatabaseHelper instance = DatabaseHelper._private();

  static Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    return openDatabase(
      join(dir.path, 'chit_notebook_v2.db'),
      version: Schema.currentVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        for (final sql in Schema.createStatements) {
          await db.execute(sql);
        }
      },
      onUpgrade: (db, oldV, newV) async {
        // Versioned migrations go here
        if (oldV < 2) {
          for (final sql in Schema.createStatements) {
            await db.execute(sql);
          }
        }
      },
    );
  }

  /// One-tap backup: whole DB as JSON. Share via share_plus, keep in Drive/WhatsApp.
  Future<String> exportJson() async {
    final db = await database;
    final dump = <String, List<Map<String, Object?>>>{};
    for (final t in Schema.tables) {
      dump[t] = await db.query(t);
    }
    return const JsonEncoder.withIndent('  ').convert({
      'app': 'chit_notebook',
      'schema_version': Schema.currentVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'data': dump,
    });
  }

  /// Restore from [exportJson] output. Replaces ALL current data inside an atomic transaction.
  Future<void> importJson(String json) async {
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    if (decoded['app'] != 'chit_notebook') {
      throw const FormatException('Invalid backup: unrecognized application header.');
    }
    final data = decoded['data'] as Map<String, dynamic>;
    final db = await database;
    await db.transaction((txn) async {
      for (final t in Schema.tables.reversed) {
        await txn.delete(t);
      }
      for (final t in Schema.tables) {
        if (data.containsKey(t)) {
          for (final row in (data[t] as List).cast<Map<String, dynamic>>()) {
            await txn.insert(t, row.cast<String, Object?>());
          }
        }
      }
    });
  }
}
