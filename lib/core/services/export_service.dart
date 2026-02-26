import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams, XFile;
import 'package:flutter_pos/core/utils/currency_formatter.dart';
import 'package:flutter_pos/core/utils/date_formatter.dart';
import 'package:flutter_pos/logic/cubits/report/report_state.dart';


class ExportService {
  /// Save Excel file (Handles both Mobile and Desktop)
  Future<String?> saveExcelFile(Excel excel, String fileName) async {
    final fileBytes = excel.save();
    if (fileBytes == null) return null;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan File Excel',
        fileName: fileName,
        allowedExtensions: ['xlsx'],
        type: FileType.custom,
      );

      if (outputFile != null) {
        String path = outputFile;
        if (!path.endsWith('.xlsx')) {
          path = '$path.xlsx';
        }

        final file = File(path);
        await file.writeAsBytes(fileBytes);
        return path;
      }
      return null;
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      return filePath;
    }
  }

  /// Export financial report to Excel
  Future<String> exportReportToExcel(ReportData reportData) async {
    final excel = Excel.createExcel();

    // Sheet 1: Ringkasan Keuangan
    _createFinancialSummarySheet(excel, reportData);

    // Sheet 2: Pengeluaran per Kategori
    _createKategoriSheet(excel, reportData);

    // Sheet 3: Tren Bulanan
    if (reportData.monthlyData.isNotEmpty) {
      _createMonthlySheet(excel, reportData);
    }

    excel.delete('Sheet1');

    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'Laporan_Keuangan_${DateFormatter.formatDateCompact(reportData.startDate)}_${DateFormatter.formatDateCompact(reportData.endDate)}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      return filePath;
    }

    throw Exception('Gagal membuat file Excel');
  }

  void _createFinancialSummarySheet(Excel excel, ReportData reportData) {
    final sheet = excel['Ringkasan Keuangan'];

    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('LAPORAN KEUANGAN RT/RW');
    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
        'Periode: ${DateFormatter.formatDate(reportData.startDate)} - ${DateFormatter.formatDate(reportData.endDate)}');

    sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue('Total Iuran (Pemasukan)');
    sheet.cell(CellIndex.indexByString('B4')).value =
        TextCellValue(CurrencyFormatter.format(reportData.totalIuran.toInt()));

    sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('Total Pengeluaran');
    sheet.cell(CellIndex.indexByString('B5')).value =
        TextCellValue(CurrencyFormatter.format(reportData.totalPengeluaran.toInt()));

    sheet.cell(CellIndex.indexByString('A6')).value = TextCellValue('Saldo');
    sheet.cell(CellIndex.indexByString('B6')).value =
        TextCellValue(CurrencyFormatter.format(reportData.saldo.toInt()));

    sheet.cell(CellIndex.indexByString('A8')).value = TextCellValue('Iuran Lunas');
    sheet.cell(CellIndex.indexByString('B8')).value = IntCellValue(reportData.jumlahIuranLunas);

    sheet.cell(CellIndex.indexByString('A9')).value = TextCellValue('Iuran Belum Bayar');
    sheet.cell(CellIndex.indexByString('B9')).value = IntCellValue(reportData.jumlahIuranBelum);
  }

  void _createKategoriSheet(Excel excel, ReportData reportData) {
    final sheet = excel['Pengeluaran per Kategori'];

    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Kategori');
    sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Jumlah');

    int row = 2;
    for (final entry in reportData.pengeluaranByKategori.entries) {
      sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(entry.key);
      sheet.cell(CellIndex.indexByString('B$row')).value =
          TextCellValue(CurrencyFormatter.format(entry.value.toInt()));
      row++;
    }
  }

  void _createMonthlySheet(Excel excel, ReportData reportData) {
    final sheet = excel['Tren Bulanan'];

    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Bulan');
    sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Iuran');
    sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Pengeluaran');
    sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('Saldo');

    int row = 2;
    for (final m in reportData.monthlyData) {
      sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(m.month);
      sheet.cell(CellIndex.indexByString('B$row')).value =
          TextCellValue(CurrencyFormatter.format(m.iuran.toInt()));
      sheet.cell(CellIndex.indexByString('C$row')).value =
          TextCellValue(CurrencyFormatter.format(m.pengeluaran.toInt()));
      sheet.cell(CellIndex.indexByString('D$row')).value =
          TextCellValue(CurrencyFormatter.format(m.saldo.toInt()));
      row++;
    }
  }

  /// Share exported file
  Future<void> shareFile(String filePath) async {
    await SharePlus.instance.share(ShareParams(
      files: [XFile(filePath)],
    ));
  }
}
