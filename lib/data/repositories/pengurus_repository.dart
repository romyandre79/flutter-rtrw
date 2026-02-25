import 'package:sqflite/sqflite.dart';
import 'package:flutter_pos/data/database/database_helper.dart';
import 'package:flutter_pos/data/models/pengurus.dart';

class PengurusRepository {
  final DatabaseHelper _dbHelper;

  PengurusRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<int> create(Pengurus pengurus) async {
    final db = await _dbHelper.database;
    return await db.insert('pengurus', pengurus.toMap());
  }

  Future<int> update(Pengurus pengurus) async {
    final db = await _dbHelper.database;
    return await db.update(
      'pengurus',
      pengurus.toMap(),
      where: 'id = ?',
      whereArgs: [pengurus.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('pengurus', where: 'id = ?', whereArgs: [id]);
  }

  Future<Pengurus?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT p.*, 
        w.nama as warga_nama,
        w.no_hp as warga_no_hp,
        w.foto_profil as warga_foto_profil
      FROM pengurus p
      LEFT JOIN warga w ON p.warga_id = w.id
      WHERE p.id = ?
    ''', [id]);
    if (maps.isEmpty) return null;
    return Pengurus.fromMap(maps.first);
  }

  Future<List<Pengurus>> getAll({
    String? status,
    String? jabatan,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;
    final where = <String>[];
    final args = <dynamic>[];

    if (status != null) {
      where.add('p.status = ?');
      args.add(status);
    }
    if (jabatan != null) {
      where.add('p.jabatan = ?');
      args.add(jabatan);
    }

    final whereClause = where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

    final maps = await db.rawQuery('''
      SELECT p.*, 
        w.nama as warga_nama,
        w.no_hp as warga_no_hp,
        w.foto_profil as warga_foto_profil
      FROM pengurus p
      LEFT JOIN warga w ON p.warga_id = w.id
      $whereClause
      ORDER BY 
        CASE p.jabatan 
          WHEN 'Ketua RT' THEN 1
          WHEN 'Wakil Ketua' THEN 2
          WHEN 'Sekretaris' THEN 3
          WHEN 'Bendahara' THEN 4
          ELSE 5
        END,
        p.status ASC
      LIMIT ? OFFSET ?
    ''', [...args, limit, offset]);

    return maps.map((m) => Pengurus.fromMap(m)).toList();
  }

  Future<List<Pengurus>> getActive() async {
    return getAll(status: 'aktif');
  }

  Future<int> getActiveCount() async {
    final db = await _dbHelper.database;
    return Sqflite.firstIntValue(
        await db.rawQuery("SELECT COUNT(*) FROM pengurus WHERE status = 'aktif'")) ?? 0;
  }
}
