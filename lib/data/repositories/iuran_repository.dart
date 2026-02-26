import 'package:sqflite/sqflite.dart';
import 'package:flutter_pos/data/database/database_helper.dart';
import 'package:flutter_pos/data/models/iuran.dart';

class IuranRepository {
  final DatabaseHelper _dbHelper;

  IuranRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<int> create(Iuran iuran) async {
    final db = await _dbHelper.database;
    return await db.insert('iuran', iuran.toMap());
  }

  Future<int> update(Iuran iuran) async {
    final db = await _dbHelper.database;
    return await db.update(
      'iuran',
      iuran.toMap(),
      where: 'id = ?',
      whereArgs: [iuran.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('iuran', where: 'id = ?', whereArgs: [id]);
  }

  Future<Iuran?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT i.*,
        w.nama as warga_nama,
        r.nomor_rumah as rumah_nomor
      FROM iuran i
      LEFT JOIN warga w ON i.warga_id = w.id
      LEFT JOIN rumah r ON i.rumah_id = r.id
      WHERE i.id = ?
    ''', [id]);
    if (maps.isEmpty) return null;
    return Iuran.fromMap(maps.first);
  }

  Future<List<Iuran>> getAll({
    String? jenis,
    String? statusBayar,
    String? periode,
    int? wargaId,
    int? rumahId,
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;
    final where = <String>[];
    final args = <dynamic>[];

    if (jenis != null) {
      where.add('i.jenis = ?');
      args.add(jenis);
    }
    if (statusBayar != null) {
      where.add('i.status_bayar = ?');
      args.add(statusBayar);
    }
    if (periode != null) {
      where.add('i.periode = ?');
      args.add(periode);
    }
    if (wargaId != null) {
      where.add('i.warga_id = ?');
      args.add(wargaId);
    }
    if (rumahId != null) {
      where.add('i.rumah_id = ?');
      args.add(rumahId);
    }

    final whereClause = where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

    final maps = await db.rawQuery('''
      SELECT i.*,
        w.nama as warga_nama,
        r.nomor_rumah as rumah_nomor
      FROM iuran i
      LEFT JOIN warga w ON i.warga_id = w.id
      LEFT JOIN rumah r ON i.rumah_id = r.id
      $whereClause
      ORDER BY i.created_at DESC
      LIMIT ? OFFSET ?
    ''', [...args, limit, offset]);

    return maps.map((m) => Iuran.fromMap(m)).toList();
  }

  Future<double> getTotalByDateRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(jumlah), 0) as total
      FROM iuran
      WHERE status_bayar = 'lunas'
        AND tanggal_bayar BETWEEN ? AND ?
    ''', [
      start.toIso8601String(),
      DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String(),
    ]);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalBelumBayar() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(jumlah), 0) as total
      FROM iuran
      WHERE status_bayar = 'belum_bayar'
    ''');
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> getCount({String? statusBayar}) async {
    final db = await _dbHelper.database;
    if (statusBayar != null) {
      return Sqflite.firstIntValue(
          await db.rawQuery("SELECT COUNT(*) FROM iuran WHERE status_bayar = ?", [statusBayar])) ?? 0;
    }
    return Sqflite.firstIntValue(
        await db.rawQuery("SELECT COUNT(*) FROM iuran")) ?? 0;
  }

  Future<Map<String, double>> getMonthlySummary(int year) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT
        substr(periode, 1, 7) as bulan,
        SUM(CASE WHEN status_bayar = 'lunas' THEN jumlah ELSE 0 END) as total_lunas
      FROM iuran
      WHERE periode LIKE ?
      GROUP BY substr(periode, 1, 7)
      ORDER BY bulan ASC
    ''', ['$year%']);

    final summary = <String, double>{};
    for (final row in result) {
      summary[row['bulan'] as String] = (row['total_lunas'] as num?)?.toDouble() ?? 0;
    }
    return summary;
  }
}
