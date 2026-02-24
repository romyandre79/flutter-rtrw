import 'package:flutter/foundation.dart';

import 'package:flutter_pos/core/api/api_service.dart';
import 'package:flutter_pos/data/database/database_helper.dart';

import 'package:flutter_pos/core/services/session_service.dart';

class SyncService {
  final ApiService _apiService;
  final DatabaseHelper _dbHelper;

  SyncService({
    required ApiService apiService,
    required DatabaseHelper dbHelper,
  })  : _apiService = apiService,
        _dbHelper = dbHelper;

  Future<void> _ensureAuthenticated() async {
    final session = await SessionService.getInstance();
    
    // Check if we have cached credentials
    if (!session.hasCachedCredentials()) {
      throw Exception('Sesi kadaluarsa. Silakan login ulang ke aplikasi untuk melakukan sinkronisasi.');
    }

    final username = session.getUsername()!;
    final password = session.getCachedPassword()!;

    // Attempt login to server
    final token = await _apiService.login(username, password);
    
    if (token != null) {
      await _apiService.setAuthToken(token);
    } else {
      throw Exception('Gagal login ke server. Periksa koneksi internet atau kredensial Anda.');
    }
  }

  // Download master data (Units only)
  Future<void> downloadMasterData() async {
    await _ensureAuthenticated();
    await _downloadUnits();
  }
  
  Future<void> _downloadUnits() async {
    try {
      final response = await _apiService.executeFlow('pos_get_units', 'pos', {});
      if (response.data['code'] == 200) {
        final List<dynamic> data = response.data['data']['data'];
        final db = await _dbHelper.database;
        
        await db.transaction((txn) async {
          for (final item in data) {
            final List<Map<String, dynamic>> existing = await txn.query(
              'units',
              where: 'server_id = ?',
              whereArgs: [item['id']],
            );
            
            final unitMap = {
              'name': item['name'],
              'server_id': item['id'],
            };

            if (existing.isNotEmpty) {
              await txn.update(
                'units',
                unitMap,
                where: 'server_id = ?',
                whereArgs: [item['id']],
              );
            } else {
              await txn.insert('units', unitMap);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error downloading units: $e');
    }
  }
}
