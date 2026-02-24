import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/data/repositories/payment_repository.dart';
import 'package:flutter_pos/logic/cubits/dashboard/dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final PaymentRepository _paymentRepository;

  DashboardCubit({
    PaymentRepository? paymentRepository,
  })  : _paymentRepository = paymentRepository ?? PaymentRepository(),
        super(const DashboardInitial());

  Future<void> loadDashboard() async {
    emit(const DashboardLoading());

    try {
      final results = await Future.wait([
        _paymentRepository.getTodayRevenue(),
        _paymentRepository.getThisMonthOrderCount(),
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
