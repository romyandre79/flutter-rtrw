import 'package:equatable/equatable.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final int totalWarga;
  final int totalRumah;
  final int totalPengurus;
  final double totalIuran;
  final double totalPengeluaran;

  const DashboardLoaded({
    required this.totalWarga,
    required this.totalRumah,
    required this.totalPengurus,
    required this.totalIuran,
    required this.totalPengeluaran,
  });

  @override
  List<Object?> get props => [totalWarga, totalRumah, totalPengurus, totalIuran, totalPengeluaran];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
