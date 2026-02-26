import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/data/repositories/warga_repository.dart';
import 'package:flutter_pos/data/repositories/rumah_repository.dart';
import 'package:flutter_pos/data/repositories/pengurus_repository.dart';
import 'package:flutter_pos/data/repositories/iuran_repository.dart';
import 'package:flutter_pos/data/repositories/pengeluaran_repository.dart';
import 'package:flutter_pos/logic/cubits/dashboard/dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final WargaRepository _wargaRepo;
  final RumahRepository _rumahRepo;
  final PengurusRepository _pengurusRepo;
  final IuranRepository _iuranRepo;
  final PengeluaranRepository _pengeluaranRepo;

  DashboardCubit({
    WargaRepository? wargaRepository,
    RumahRepository? rumahRepository,
    PengurusRepository? pengurusRepository,
    IuranRepository? iuranRepository,
    PengeluaranRepository? pengeluaranRepository,
  })  : _wargaRepo = wargaRepository ?? WargaRepository(),
        _rumahRepo = rumahRepository ?? RumahRepository(),
        _pengurusRepo = pengurusRepository ?? PengurusRepository(),
        _iuranRepo = iuranRepository ?? IuranRepository(),
        _pengeluaranRepo = pengeluaranRepository ?? PengeluaranRepository(),
        super(const DashboardInitial());

  Future<void> loadDashboard() async {
    emit(const DashboardLoading());

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final results = await Future.wait([
        _wargaRepo.getCount(status: 'aktif'),
        _rumahRepo.getCount(),
        _pengurusRepo.getActiveCount(),
        _iuranRepo.getTotalByDateRange(startOfMonth, endOfMonth),
        _pengeluaranRepo.getTotalByDateRange(startOfMonth, endOfMonth),
      ]);

      emit(DashboardLoaded(
        totalWarga: results[0] as int,
        totalRumah: results[1] as int,
        totalPengurus: results[2] as int,
        totalIuran: results[3] as double,
        totalPengeluaran: results[4] as double,
      ));
    } catch (e) {
      emit(DashboardError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
