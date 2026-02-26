import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/data/repositories/report_repository.dart';
import 'package:flutter_pos/logic/cubits/report/report_state.dart';

class ReportCubit extends Cubit<ReportState> {
  final ReportRepository _reportRepository;

  ReportCubit({
    ReportRepository? reportRepository,
  })  : _reportRepository = reportRepository ?? ReportRepository(),
        super(const ReportInitial());

  /// Load report data
  Future<void> loadReport(DateTime startDate, DateTime endDate) async {
    emit(const ReportLoading());

    try {
      final data = await _reportRepository.getReportData(startDate, endDate);
      emit(ReportLoaded(data: data));
    } catch (e) {
      emit(ReportError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
