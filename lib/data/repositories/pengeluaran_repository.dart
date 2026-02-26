import 'package:sqflite/sqflite.dart';
import 'package:flutter_pos/data/database/database_helper.dart';
import 'package:flutter_pos/data/models/pengeluaran.dart';

class PengeluaranRepository {
  final DatabaseHelper _dbHelper;

  PengeluaranRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<int> create(Pengeluaran pengeluaran) async {
    final db = await _dbHelper.database;
    return await db.insert('pengeluaran', pengeluaran.toMap());
  }

  Future<int> update(Pengeluaran pengeluaran) async {
    final db = await _dbHelper.database;
    return await db.update(
      'pengeluaran',
      pengeluaran.toMap(),
      where: 'id = ?',
      whereArgs: [pengeluaran.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('pengeluaran', where: 'id = ?', whereArgs: [id]);
  }

  Future<Pengeluaran?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('pengeluaran', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Pengeluaran.fromMap(maps.first);
  }

  Future<List<Pengeluaran>> getAll({
    String? kategori,
    String? startDate,
    String? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;
    final where = <String>[];
    final args = <dynamic>[];

    if (kategori != null) {
      where.add('kategori = ?');
      args.add(kategori);
    }
    if (startDate != null) {
      where.add('tanggal >= ?');
      args.add(startDate);
    }
    if (endDate != null) {
      where.add('tanggal <= ?');
      args.add(endDate);
    }

    final whereClause = where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

    final maps = await db.rawQuery('''
      SELECT * FROM pengeluaran
      $whereClause
      ORDER BY tanggal DESC, created_at DESC
      LIMIT ? OFFSET ?
    ''', [...args, limit, offset]);

    return maps.map((m) => Pengeluaran.fromMap(m)).toList();
  }

  Future<double> getTotalByDateRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final startStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final endStr = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(jumlah), 0) as total
      FROM pengeluaran
      WHERE tanggal BETWEEN ? AND ?
    ''', [startStr, endStr]);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> getCount() async {
    final db = await _dbHelper.database;
    return Sqflite.firstIntValue(
        await db.rawQuery("SELECT COUNT(*) FROM pengeluaran")) ?? 0;
  }

  Future<Map<String, double>> getByKategoriSummary(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final startStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final endStr = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
    final result = await db.rawQuery('''
      SELECT kategori, SUM(jumlah) as total
      FROM pengeluaran
      WHERE tanggal BETWEEN ? AND ?
      GROUP BY kategori
      ORDER BY total DESC
    ''', [startStr, endStr]);

    final summary = <String, double>{};
    for (final row in result) {
      summary[row['kategori'] as String] = (row['total'] as num?)?.toDouble() ?? 0;
    }
    return summary;
  }

  Future<Map<String, double>> getMonthlySummary(int year) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT
        substr(tanggal, 1, 7) as bulan,
        SUM(jumlah) as total
      FROM pengeluaran
      WHERE tanggal LIKE ?
      GROUP BY substr(tanggal, 1, 7)
      ORDER BY bulan ASC
    ''', ['$year%']);

    final summary = <String, double>{};
    for (final row in result) {
      summary[row['bulan'] as String] = (row['total'] as num?)?.toDouble() ?? 0;
    }
    return summary;
  }
}
