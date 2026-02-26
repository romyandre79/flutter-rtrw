import 'package:equatable/equatable.dart';

class ReportData {
  final DateTime startDate;
  final DateTime endDate;
  final double totalIuran;
  final double totalPengeluaran;
  final double saldo;
  final int jumlahIuranLunas;
  final int jumlahIuranBelum;
  final List<MonthlyFinance> monthlyData;
  final Map<String, double> pengeluaranByKategori;

  ReportData({
    required this.startDate,
    required this.endDate,
    required this.totalIuran,
    required this.totalPengeluaran,
    required this.saldo,
    required this.jumlahIuranLunas,
    required this.jumlahIuranBelum,
    required this.monthlyData,
    required this.pengeluaranByKategori,
  });
}

class MonthlyFinance {
  final String month; // "2026-01"
  final double iuran;
  final double pengeluaran;

  MonthlyFinance({
    required this.month,
    required this.iuran,
    required this.pengeluaran,
  });

  double get saldo => iuran - pengeluaran;
}

// Keep these for backward compatibility but they won't be used
class DailyRevenue {
  final DateTime date;
  final int revenue;
  final int orderCount;
  final int paid;
  final int profit;

  DailyRevenue({
    required this.date,
    required this.revenue,
    required this.orderCount,
    this.paid = 0,
    this.profit = 0,
  });
}

class ServiceSummary {
  final String serviceName;
  final int totalQuantity;
  final int totalRevenue;
  final int orderCount;

  ServiceSummary({
    required this.serviceName,
    required this.totalQuantity,
    required this.totalRevenue,
    required this.orderCount,
  });
}

abstract class ReportState extends Equatable {
  const ReportState();

  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {
  const ReportInitial();
}

class ReportLoading extends ReportState {
  const ReportLoading();
}

class ReportLoaded extends ReportState {
  final ReportData data;

  const ReportLoaded({required this.data});

  @override
  List<Object?> get props => [data];
}

class ReportExporting extends ReportState {
  const ReportExporting();
}

class ReportExported extends ReportState {
  final String filePath;
  final String message;

  const ReportExported({required this.filePath, required this.message});

  @override
  List<Object?> get props => [filePath, message];
}

class ReportError extends ReportState {
  final String message;

  const ReportError(this.message);

  @override
  List<Object?> get props => [message];
}
