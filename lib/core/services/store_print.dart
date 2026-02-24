import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_pos/data/repositories/settings_repository.dart';
import 'package:flutter_pos/core/utils/date_formatter.dart';
import 'package:flutter_pos/core/constants/app_constants.dart';

class StorePrint {
  StorePrint._init();

  static final StorePrint instance = StorePrint._init();

  final SettingsRepository _settingsRepository = SettingsRepository();

  Future<Map<String, String>> _getStoreInfo() async {
    final settings = await _settingsRepository.getAllSettings();
    return {
      'name': settings[AppConstants.keyStoreName] ??
          AppConstants.defaultStoreName,
      'address': settings[AppConstants.keyStoreAddress] ??
          AppConstants.defaultStoreAddress,
      'phone': settings[AppConstants.keyStorePhone] ??
          AppConstants.defaultStorePhone,
    };
  }

  /// Print test receipt to verify printer connection
  Future<List<int>> printTest({
    PaperSize paperSize = PaperSize.mm58,
    String paperSizeMm = '58',
  }) async {
    List<int> bytes = [];

    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);

    // Get store info from settings
    final storeInfo = await _getStoreInfo();

    final String separator = paperSizeMm == '80'
        ? '------------------------------------------------'
        : '--------------------------------';

    bytes += generator.reset();

    // Header
    bytes += generator.text(
      storeInfo['name'] ?? 'Toko',
      styles: const PosStyles(
        bold: true,
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size1,
      ),
    );

    bytes += generator.text(
      separator,
      styles: const PosStyles(bold: false, align: PosAlign.center),
    );

    bytes += generator.text(
      'TEST PRINT',
      styles: const PosStyles(
        bold: true,
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    bytes += generator.text(
      separator,
      styles: const PosStyles(bold: false, align: PosAlign.center),
    );

    bytes += generator.text(
      'Printer terhubung dengan baik!',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.text(
      'Ukuran kertas: ${paperSizeMm}mm',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.text(
      separator,
      styles: const PosStyles(bold: false, align: PosAlign.center),
    );

    bytes += generator.text(
      DateFormatter.formatDateTime(DateTime.now()),
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.feed(3);

    if (paperSizeMm == '80') {
      bytes += generator.cut();
    }

    return bytes;
  }
}
