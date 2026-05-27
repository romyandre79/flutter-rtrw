import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pos/core/constants/app_constants.dart';
import 'package:flutter_pos/core/utils/password_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final path = await getDbPath();

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: _configureDB,
    );
  }

  Future<void> _configureDB(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // App Settings table
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Rumah (Houses) table
    await db.execute('''
      CREATE TABLE rumah (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nomor_rumah TEXT NOT NULL,
        blok TEXT,
        alamat TEXT,
        rt TEXT,
        rw TEXT,
        status_kepemilikan TEXT DEFAULT 'Milik Sendiri',
        luas_tanah REAL,
        luas_bangunan REAL,
        foto TEXT,
        catatan TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Warga (Residents) table
    await db.execute('''
      CREATE TABLE warga (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nik TEXT UNIQUE,
        nama TEXT NOT NULL,
        tempat_lahir TEXT,
        tanggal_lahir TEXT,
        jenis_kelamin TEXT,
        agama TEXT,
        status_perkawinan TEXT,
        pekerjaan TEXT,
        pendidikan TEXT,
        no_kk TEXT,
        status_kk TEXT,
        no_hp TEXT,
        alamat TEXT,
        rt TEXT,
        rw TEXT,
        rumah_id INTEGER,
        kepemilikan_rumah TEXT,
        foto_ktp TEXT,
        foto_kk TEXT,
        foto_profil TEXT,
        status TEXT DEFAULT 'aktif',
        catatan TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (rumah_id) REFERENCES rumah(id) ON DELETE SET NULL
      )
    ''');

    // Pengurus (Officials) table
    await db.execute('''
      CREATE TABLE pengurus (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        warga_id INTEGER,
        jabatan TEXT NOT NULL,
        periode_mulai TEXT,
        periode_selesai TEXT,
        status TEXT DEFAULT 'aktif',
        catatan TEXT,
        foto TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (warga_id) REFERENCES warga(id) ON DELETE SET NULL
      )
    ''');

    // Iuran (Dues) table
    await db.execute('''
      CREATE TABLE iuran (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        warga_id INTEGER,
        rumah_id INTEGER,
        jenis TEXT NOT NULL DEFAULT 'bulanan',
        keterangan TEXT,
        jumlah REAL NOT NULL DEFAULT 0,
        periode TEXT,
        tanggal_bayar TEXT,
        status_bayar TEXT DEFAULT 'belum_bayar',
        bukti_pembayaran TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (warga_id) REFERENCES warga(id) ON DELETE SET NULL,
        FOREIGN KEY (rumah_id) REFERENCES rumah(id) ON DELETE SET NULL
      )
    ''');

    // Pengeluaran (Expenses) table
    await db.execute('''
      CREATE TABLE pengeluaran (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kategori TEXT NOT NULL,
        keterangan TEXT,
        jumlah REAL NOT NULL DEFAULT 0,
        tanggal TEXT NOT NULL,
        bukti_pengeluaran TEXT,
        created_by INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
      )
    ''');

    // Denah Pin (Map pins for warga location) table
    await db.execute('''
      CREATE TABLE denah_pin (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        warga_id INTEGER,
        rumah_id INTEGER,
        x_percent REAL NOT NULL,
        y_percent REAL NOT NULL,
        label TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (warga_id) REFERENCES warga(id) ON DELETE CASCADE,
        FOREIGN KEY (rumah_id) REFERENCES rumah(id) ON DELETE SET NULL
      )
    ''');
    
    // Units table
    await db.execute('''
      CREATE TABLE units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await _createIndexes(db);
    await _seedData(db);
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_users_username ON users(username)');
    await db.execute('CREATE INDEX idx_users_role ON users(role)');

    // Warga indexes
    await db.execute('CREATE INDEX idx_warga_nik ON warga(nik)');
    await db.execute('CREATE INDEX idx_warga_nama ON warga(nama)');
    await db.execute('CREATE INDEX idx_warga_no_kk ON warga(no_kk)');
    await db.execute('CREATE INDEX idx_warga_rumah ON warga(rumah_id)');
    await db.execute('CREATE INDEX idx_warga_status ON warga(status)');
    await db.execute('CREATE INDEX idx_warga_rt_rw ON warga(rt, rw)');

    // Rumah indexes
    await db.execute('CREATE INDEX idx_rumah_nomor ON rumah(nomor_rumah)');
    await db.execute('CREATE INDEX idx_rumah_blok ON rumah(blok)');
    await db.execute('CREATE INDEX idx_rumah_rt_rw ON rumah(rt, rw)');

    // Pengurus indexes
    await db.execute('CREATE INDEX idx_pengurus_warga ON pengurus(warga_id)');
    await db.execute('CREATE INDEX idx_pengurus_jabatan ON pengurus(jabatan)');
    await db.execute('CREATE INDEX idx_pengurus_status ON pengurus(status)');

    // Iuran indexes
    await db.execute('CREATE INDEX idx_iuran_warga ON iuran(warga_id)');
    await db.execute('CREATE INDEX idx_iuran_rumah ON iuran(rumah_id)');
    await db.execute('CREATE INDEX idx_iuran_jenis ON iuran(jenis)');
    await db.execute('CREATE INDEX idx_iuran_periode ON iuran(periode)');
    await db.execute('CREATE INDEX idx_iuran_status ON iuran(status_bayar)');

    // Pengeluaran indexes
    await db.execute('CREATE INDEX idx_pengeluaran_kategori ON pengeluaran(kategori)');
    await db.execute('CREATE INDEX idx_pengeluaran_tanggal ON pengeluaran(tanggal)');

    // Denah Pin indexes
    await db.execute('CREATE INDEX idx_denah_pin_warga ON denah_pin(warga_id)');
  }

  Future<void> _seedData(Database db) async {
    // Seed default owner
    final passwordHash = PasswordHelper.hashPassword(AppConstants.defaultOwnerPassword);
    await db.insert('users', {
      'username': AppConstants.defaultOwnerUsername,
      'password_hash': passwordHash,
      'name': AppConstants.defaultOwnerName,
      'role': 'owner',
      'is_active': 1,
    });

    // Seed default settings
    final settings = {
      AppConstants.keyStoreName: AppConstants.defaultRTName,
      AppConstants.keyStoreAddress: AppConstants.defaultRTAddress,
      AppConstants.keyStorePhone: AppConstants.defaultRTPhone,
      AppConstants.keyInvoicePrefix: AppConstants.defaultSuratKeluarPrefix,
      AppConstants.keyPrinterAddress: '',
      AppConstants.keyLastInvoiceDate: '',
      AppConstants.keyLastInvoiceNumber: '0',
      AppConstants.keyFonnteToken: '',
    };

    for (final entry in settings.entries) {
      await db.insert('app_settings', {
        'key': entry.key,
        'value': entry.value,
      });
    }

    // Seed default units
    final defaultUnits = ['pcs', 'kg', 'box', 'liter', 'ls', 'unit'];
    for (final unit in defaultUnits) {
      await db.insert('units', {'name': unit});
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 8) {
      // Add foto column to pengurus
      await db.execute('ALTER TABLE pengurus ADD COLUMN foto TEXT');
      // Create iuran table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS iuran (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          warga_id INTEGER,
          rumah_id INTEGER,
          jenis TEXT NOT NULL DEFAULT 'bulanan',
          keterangan TEXT,
          jumlah REAL NOT NULL DEFAULT 0,
          periode TEXT,
          tanggal_bayar TEXT,
          status_bayar TEXT DEFAULT 'belum_bayar',
          bukti_pembayaran TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (warga_id) REFERENCES warga(id) ON DELETE SET NULL,
          FOREIGN KEY (rumah_id) REFERENCES rumah(id) ON DELETE SET NULL
        )
      ''');
      // Create pengeluaran table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pengeluaran (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          kategori TEXT NOT NULL,
          keterangan TEXT,
          jumlah REAL NOT NULL DEFAULT 0,
          tanggal TEXT NOT NULL,
          bukti_pengeluaran TEXT,
          created_by INTEGER,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
        )
      ''');
      // Create indexes for new tables
      await db.execute('CREATE INDEX IF NOT EXISTS idx_iuran_warga ON iuran(warga_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_iuran_rumah ON iuran(rumah_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_iuran_jenis ON iuran(jenis)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_iuran_periode ON iuran(periode)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_iuran_status ON iuran(status_bayar)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_pengeluaran_kategori ON pengeluaran(kategori)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_pengeluaran_tanggal ON pengeluaran(tanggal)');
      // Create denah_pin table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS denah_pin (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          warga_id INTEGER,
          rumah_id INTEGER,
          x_percent REAL NOT NULL,
          y_percent REAL NOT NULL,
          label TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (warga_id) REFERENCES warga(id) ON DELETE CASCADE,
          FOREIGN KEY (rumah_id) REFERENCES rumah(id) ON DELETE SET NULL
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_denah_pin_warga ON denah_pin(warga_id)');
    }

    if (oldVersion < 9) {
      // Create denah_pin table (for users who already migrated to v8)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS denah_pin (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          warga_id INTEGER,
          rumah_id INTEGER,
          x_percent REAL NOT NULL,
          y_percent REAL NOT NULL,
          label TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (warga_id) REFERENCES warga(id) ON DELETE CASCADE,
          FOREIGN KEY (rumah_id) REFERENCES rumah(id) ON DELETE SET NULL
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_denah_pin_warga ON denah_pin(warga_id)');
    }

    if (oldVersion < 10) {
      try {
        await db.execute('ALTER TABLE warga ADD COLUMN kepemilikan_rumah TEXT');
      } catch (e) {
        // Ignore if exists
      }
    }

    if (oldVersion < 11) {
      try {
        await db.execute('ALTER TABLE warga ADD COLUMN pendidikan TEXT');
      } catch (e) {
        // Ignore if exists
      }
    }

    if (oldVersion < 12) {
      // Create pengumuman_template table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pengumuman_template (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          judul TEXT,
          isi TEXT NOT NULL,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
    }

    if (oldVersion < 13) {
      // Add units table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS units (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT UNIQUE NOT NULL,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Seed default units if table was just created
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM units'));
      if (count == 0 || count == null) {
        final defaultUnits = ['pcs', 'kg', 'box', 'liter', 'ls', 'unit'];
        for (final unit in defaultUnits) {
          await db.insert('units', {'name': unit});
        }
      }
    }
  }

  Future<String> getDbPath() async {
    final String dbPath;
    if (Platform.isWindows) {
      dbPath = dirname(Platform.resolvedExecutable);
    } else if (Platform.isLinux || Platform.isMacOS) {
      final docsDir = await getApplicationDocumentsDirectory();
      dbPath = docsDir.path;
    } else {
      dbPath = await getDatabasesPath();
    }
    return join(dbPath, AppConstants.databaseName);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }

  Future<void> deleteDatabase() async {
    final path = await getDbPath();
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  Future<void> resetDatabase() async {
    await deleteDatabase();
    await database;
  }
}
