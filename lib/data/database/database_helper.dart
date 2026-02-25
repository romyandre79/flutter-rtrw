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
    final String dbPath;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final docsDir = await getApplicationDocumentsDirectory();
      dbPath = docsDir.path;
    } else {
      dbPath = await getDatabasesPath();
    }
    final path = join(dbPath, filePath);

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
        no_kk TEXT,
        status_kk TEXT,
        no_hp TEXT,
        alamat TEXT,
        rt TEXT,
        rw TEXT,
        rumah_id INTEGER,
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
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (warga_id) REFERENCES warga(id) ON DELETE SET NULL
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
    };

    for (final entry in settings.entries) {
      await db.insert('app_settings', {
        'key': entry.key,
        'value': entry.value,
      });
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
  }

  Future<String> getDbPath() async {
    final String dbPath;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
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
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  Future<void> resetDatabase() async {
    await deleteDatabase();
    await database;
  }
}
