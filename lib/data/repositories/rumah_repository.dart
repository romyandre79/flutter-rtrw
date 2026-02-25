import 'package:sqflite/sqflite.dart';
import 'package:flutter_pos/data/database/database_helper.dart';
import 'package:flutter_pos/data/models/rumah.dart';

class RumahRepository {
  final DatabaseHelper _dbHelper;

  RumahRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<int> create(Rumah rumah) async {
    final db = await _dbHelper.database;
    return await db.insert('rumah', rumah.toMap());
  }

  Future<int> update(Rumah rumah) async {
    final db = await _dbHelper.database;
    return await db.update(
      'rumah',
      rumah.toMap(),
      where: 'id = ?',
      whereArgs: [rumah.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('rumah', where: 'id = ?', whereArgs: [id]);
  }

  Future<Rumah?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT r.*, 
        (SELECT COUNT(*) FROM warga w WHERE w.rumah_id = r.id AND w.status = 'aktif') as penghuni_count
      FROM rumah r WHERE r.id = ?
    ''', [id]);
    if (maps.isEmpty) return null;
    return Rumah.fromMap(maps.first);
  }

  Future<List<Rumah>> getAll({
    String? search,
    String? rt,
    String? rw,
    String? blok,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;
    final where = <String>[];
    final args = <dynamic>[];

    if (search != null && search.isNotEmpty) {
      where.add('(r.nomor_rumah LIKE ? OR r.blok LIKE ? OR r.alamat LIKE ?)');
      args.addAll(['%$search%', '%$search%', '%$search%']);
    }
    if (rt != null) {
      where.add('r.rt = ?');
      args.add(rt);
    }
    if (rw != null) {
      where.add('r.rw = ?');
      args.add(rw);
    }
    if (blok != null) {
      where.add('r.blok = ?');
      args.add(blok);
    }

    final whereClause = where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

    final maps = await db.rawQuery('''
      SELECT r.*, 
        (SELECT COUNT(*) FROM warga w WHERE w.rumah_id = r.id AND w.status = 'aktif') as penghuni_count
      FROM rumah r
      $whereClause
      ORDER BY r.blok ASC, r.nomor_rumah ASC
      LIMIT ? OFFSET ?
    ''', [...args, limit, offset]);

    return maps.map((m) => Rumah.fromMap(m)).toList();
  }

  Future<int> getCount() async {
    final db = await _dbHelper.database;
    return Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM rumah')) ?? 0;
  }

  Future<List<String>> getDistinctBlok() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT blok FROM rumah WHERE blok IS NOT NULL AND blok != \'\' ORDER BY blok',
    );
    return result.map((r) => r['blok'] as String).toList();
  }
}
