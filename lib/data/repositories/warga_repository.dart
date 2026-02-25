import 'package:sqflite/sqflite.dart';
import 'package:flutter_pos/data/database/database_helper.dart';
import 'package:flutter_pos/data/models/warga.dart';

class WargaRepository {
  final DatabaseHelper _dbHelper;

  WargaRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<int> create(Warga warga) async {
    final db = await _dbHelper.database;
    return await db.insert('warga', warga.toMap());
  }

  Future<int> update(Warga warga) async {
    final db = await _dbHelper.database;
    return await db.update(
      'warga',
      warga.toMap(),
      where: 'id = ?',
      whereArgs: [warga.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('warga', where: 'id = ?', whereArgs: [id]);
  }

  Future<Warga?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('warga', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Warga.fromMap(maps.first);
  }

  Future<Warga?> getByNik(String nik) async {
    final db = await _dbHelper.database;
    final maps = await db.query('warga', where: 'nik = ?', whereArgs: [nik]);
    if (maps.isEmpty) return null;
    return Warga.fromMap(maps.first);
  }

  Future<List<Warga>> getAll({
    String? search,
    String? status,
    String? rt,
    String? rw,
    int? rumahId,
    String? noKk,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;
    final where = <String>[];
    final args = <dynamic>[];

    if (search != null && search.isNotEmpty) {
      where.add('(nama LIKE ? OR nik LIKE ? OR no_hp LIKE ?)');
      args.addAll(['%$search%', '%$search%', '%$search%']);
    }
    if (status != null) {
      where.add('status = ?');
      args.add(status);
    }
    if (rt != null) {
      where.add('rt = ?');
      args.add(rt);
    }
    if (rw != null) {
      where.add('rw = ?');
      args.add(rw);
    }
    if (rumahId != null) {
      where.add('rumah_id = ?');
      args.add(rumahId);
    }
    if (noKk != null) {
      where.add('no_kk = ?');
      args.add(noKk);
    }

    final maps = await db.query(
      'warga',
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'nama ASC',
      limit: limit,
      offset: offset,
    );

    return maps.map((m) => Warga.fromMap(m)).toList();
  }

  Future<List<Warga>> getByRumahId(int rumahId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'warga',
      where: 'rumah_id = ?',
      whereArgs: [rumahId],
      orderBy: 'nama ASC',
    );
    return maps.map((m) => Warga.fromMap(m)).toList();
  }

  Future<List<Warga>> getKeluarga(String noKk) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'warga',
      where: 'no_kk = ?',
      whereArgs: [noKk],
      orderBy: 'status_kk ASC, nama ASC',
    );
    return maps.map((m) => Warga.fromMap(m)).toList();
  }

  Future<int> getCount({String? status}) async {
    final db = await _dbHelper.database;
    String query = 'SELECT COUNT(*) FROM warga';
    List<dynamic> args = [];
    if (status != null) {
      query += ' WHERE status = ?';
      args.add(status);
    }
    return Sqflite.firstIntValue(await db.rawQuery(query, args)) ?? 0;
  }

  Future<Map<String, int>> getStatsByGender() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT jenis_kelamin, COUNT(*) as count
      FROM warga WHERE status = 'aktif'
      GROUP BY jenis_kelamin
    ''');
    final stats = <String, int>{};
    for (final row in result) {
      final gender = (row['jenis_kelamin'] as String?) ?? 'unknown';
      stats[gender] = (row['count'] as int?) ?? 0;
    }
    return stats;
  }
}
