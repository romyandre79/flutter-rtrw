import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/data/repositories/report_repository.dart';
import 'package:flutter_pos/logic/cubits/dashboard/dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final ReportRepository _reportRepository;

  DashboardCubit({
    ReportRepository? reportRepository,
  })  : _reportRepository = reportRepository ?? ReportRepository(),
        super(const DashboardInitial());

  Future<void> loadDashboard() async {
    emit(const DashboardLoading());

    try {
      final results = await Future.wait([
        _reportRepository.getTodayRevenue(),
        _reportRepository.getThisMonthOrderCount(),
      ]);

      emit(DashboardLoaded(
        todayRevenue: results[0],
        monthOrderCount: results[1],
      ));
    } catch (e) {
      emit(DashboardError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
