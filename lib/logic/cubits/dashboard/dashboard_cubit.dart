import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/data/repositories/warga_repository.dart';
import 'package:flutter_pos/data/repositories/rumah_repository.dart';
import 'package:flutter_pos/data/repositories/pengurus_repository.dart';
import 'package:flutter_pos/logic/cubits/dashboard/dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final WargaRepository _wargaRepo;
  final RumahRepository _rumahRepo;
  final PengurusRepository _pengurusRepo;

  DashboardCubit({
    WargaRepository? wargaRepository,
    RumahRepository? rumahRepository,
    PengurusRepository? pengurusRepository,
  })  : _wargaRepo = wargaRepository ?? WargaRepository(),
        _rumahRepo = rumahRepository ?? RumahRepository(),
        _pengurusRepo = pengurusRepository ?? PengurusRepository(),
        super(const DashboardInitial());

  Future<void> loadDashboard() async {
    emit(const DashboardLoading());

    try {
      final results = await Future.wait([
        _wargaRepo.getCount(status: 'aktif'),
        _rumahRepo.getCount(),
        _pengurusRepo.getActiveCount(),
      ]);

      emit(DashboardLoaded(
        totalWarga: results[0],
        totalRumah: results[1],
        totalPengurus: results[2],
      ));
    } catch (e) {
      emit(DashboardError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
