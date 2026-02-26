class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Kreatif - Wargamu';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Aplikasi Kreatif RT/RW - Full, Jalan Tanpa Internet!';

  // Database
  static const String databaseName = 'kreatifrtwrw.db';
  static const int databaseVersion = 11;

  // Surat Keluar
  static const String defaultSuratKeluarPrefix = 'SKel';
  static const int invoiceNumberLength = 6;

  // Default Values
  static const int defaultPageSize = 20;
  static const int recentOrdersLimit = 5;

  // Date Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String dateTimeFormat = 'dd MMM yyyy HH:mm';
  static const String dateFormatShort = 'dd/MM/yy';
  static const String timeFormat = 'HH:mm';
  static const String invoiceDateFormat = 'yyMMdd';

  // Printer
  static const int printerPaperWidth = 58; // mm
  static const int printerCharPerLine = 32;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 20;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;

  // Default Admin Credentials
  static const String defaultOwnerUsername = 'admin';
  static const String defaultOwnerPassword = 'admin';
  static const String defaultOwnerName = 'Administrator';

  // Settings Keys
  static const String keyStoreName = 'rtrw_name';
  static const String keyStoreAddress = 'rtrw_address';
  static const String keyStorePhone = 'rtrw_phone';
  static const String keyInvoicePrefix = 'surat_keluar_prefix';
  static const String keyPrinterAddress = 'printer_address';
  static const String keyLastInvoiceDate = 'last_invoice_date';

  static const String keyLastInvoiceNumber = 'last_invoice_number';

  // Plant Settings Keys
  static const String keyPlantName = 'plant_name';
  static const String keyPlantAddress = 'plant_address';
  static const String keyPlantCode = 'plant_code';
  static const String keyMachineNumber = 'machine_number';

  // Specific Settings Keys
  static const String keyIuranBulanan = 'iuran_bulanan';

  // Default RT/RW Info
  static const String defaultRTName = 'RT 01';
  static const String defaultRWName = 'RW 01';
  static const String defaultRTAddress = 'Indonesia';
  static const String defaultRWAddress = 'Indonesia';
  static const String defaultRTPhone = '-';
  static const String defaultRWPhone = '-';

  // Backward-compatible aliases
  static const String defaultStoreName = defaultRTName;
  static const String defaultStoreAddress = defaultRTAddress;
  static const String defaultStorePhone = defaultRTPhone;
  static const String defaultInvoicePrefix = defaultSuratKeluarPrefix;
  static const String defaultMachineNumber = '01';

  static const bool isDemo = true;
}
