import 'package:flutter_pos/data/repositories/iuran_repository.dart';
import 'package:flutter_pos/data/repositories/pengeluaran_repository.dart';
import 'package:flutter_pos/logic/cubits/report/report_state.dart';

class ReportRepository {
  final IuranRepository _iuranRepo;
  final PengeluaranRepository _pengeluaranRepo;

  ReportRepository({
    IuranRepository? iuranRepository,
    PengeluaranRepository? pengeluaranRepository,
  })  : _iuranRepo = iuranRepository ?? IuranRepository(),
        _pengeluaranRepo = pengeluaranRepository ?? PengeluaranRepository();

  /// Get financial report data for date range
  Future<ReportData> getReportData(
    DateTime startDate,
    DateTime endDate,
  ) async {

    // Total iuran lunas in date range
    final totalIuran = await _iuranRepo.getTotalByDateRange(startDate, endDate);

    // Total pengeluaran in date range
    final totalPengeluaran = await _pengeluaranRepo.getTotalByDateRange(startDate, endDate);

    // Count iuran by status
    final iuranLunasCount = await _iuranRepo.getCount(statusBayar: 'lunas');
    final iuranBelumCount = await _iuranRepo.getCount(statusBayar: 'belum_bayar');

    // Pengeluaran by kategori
    final pengeluaranByKategori = await _pengeluaranRepo.getByKategoriSummary(startDate, endDate);

    // Monthly data for the year
    final year = startDate.year;
    final iuranMonthly = await _iuranRepo.getMonthlySummary(year);
    final pengeluaranMonthly = await _pengeluaranRepo.getMonthlySummary(year);

    // Combine monthly data
    final allMonths = <String>{...iuranMonthly.keys, ...pengeluaranMonthly.keys};
    final monthlyData = allMonths.map((month) {
      return MonthlyFinance(
        month: month,
        iuran: iuranMonthly[month] ?? 0,
        pengeluaran: pengeluaranMonthly[month] ?? 0,
      );
    }).toList();
    monthlyData.sort((a, b) => a.month.compareTo(b.month));

    return ReportData(
      startDate: startDate,
      endDate: endDate,
      totalIuran: totalIuran,
      totalPengeluaran: totalPengeluaran,
      saldo: totalIuran - totalPengeluaran,
      jumlahIuranLunas: iuranLunasCount,
      jumlahIuranBelum: iuranBelumCount,
      monthlyData: monthlyData,
      pengeluaranByKategori: pengeluaranByKategori,
    );
  }
}
