import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/constants/app_constants.dart';
import 'package:flutter_pos/data/models/iuran.dart';
import 'package:flutter_pos/data/repositories/iuran_repository.dart';
import 'package:flutter_pos/logic/cubits/iuran/iuran_state.dart';

class IuranCubit extends Cubit<IuranState> {
  final IuranRepository _repository;

  IuranCubit({IuranRepository? repository})
      : _repository = repository ?? IuranRepository(),
        super(IuranInitial());

  Future<void> loadAll({String? jenis, String? statusBayar, String? periode}) async {
    emit(IuranLoading());
    try {
      final list = await _repository.getAll(
        jenis: jenis,
        statusBayar: statusBayar,
        periode: periode,
      );

      // Calculate totals  
      double totalLunas = 0;
      double totalBelumBayar = 0;
      for (final i in list) {
        if (i.statusBayar == 'lunas') {
          totalLunas += i.jumlah;
        } else {
          totalBelumBayar += i.jumlah;
        }
      }

      emit(IuranLoaded(
        iuranList: list,
        totalLunas: totalLunas,
        totalBelumBayar: totalBelumBayar,
      ));
    } catch (e) {
      emit(IuranError(e.toString()));
    }
  }

  Future<void> save(Iuran iuran) async {
    try {
      if (iuran.id != null) {
        await _repository.update(iuran);
        emit(const IuranSaved('Data iuran berhasil diperbarui'));
      } else {
        if (AppConstants.isDemo) {
          final count = await _repository.getCount();
          if (count >= 10) {
            emit(const IuranError('Anda telah melebihi batas transaksi aplikasi demo, silakan beli hubungi Sales Kreatif atau ke 081932701147'));
            return;
          }
        }
        await _repository.create(iuran);
        emit(const IuranSaved('Data iuran berhasil ditambahkan'));
      }
    } catch (e) {
      emit(IuranError(e.toString()));
    }
  }

  Future<void> delete(int id) async {
    try {
      await _repository.delete(id);
      emit(IuranDeleted());
    } catch (e) {
      emit(IuranError(e.toString()));
    }
  }
}
