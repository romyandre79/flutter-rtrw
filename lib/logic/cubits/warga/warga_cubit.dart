import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/constants/app_constants.dart';
import 'package:flutter_pos/data/models/warga.dart';
import 'package:flutter_pos/data/repositories/warga_repository.dart';
import 'package:flutter_pos/logic/cubits/warga/warga_state.dart';

class WargaCubit extends Cubit<WargaState> {
  final WargaRepository _repository;

  WargaCubit({WargaRepository? repository})
      : _repository = repository ?? WargaRepository(),
        super(WargaInitial());

  Future<void> loadAll({String? search, String? status}) async {
    emit(WargaLoading());
    try {
      final list = await _repository.getAll(search: search, status: status);
      final count = await _repository.getCount(status: 'aktif');
      emit(WargaLoaded(wargaList: list, totalCount: count));
    } catch (e) {
      emit(WargaError(e.toString()));
    }
  }

  Future<void> loadDetail(int id) async {
    emit(WargaLoading());
    try {
      final warga = await _repository.getById(id);
      if (warga != null) {
        emit(WargaDetailLoaded(warga));
      } else {
        emit(const WargaError('Data warga tidak ditemukan'));
      }
    } catch (e) {
      emit(WargaError(e.toString()));
    }
  }

  Future<void> save(Warga warga) async {
    try {
      if (warga.id != null) {
        await _repository.update(warga);
        emit(const WargaSaved('Data warga berhasil diperbarui'));
      } else {
        if (AppConstants.isDemo) {
          final count = await _repository.getCount();
          if (count >= 10) {
            emit(const WargaError('Anda telah melebihi batas transaksi aplikasi demo, silakan beli hubungi Sales Kreatif atau ke 081932701147'));
            return;
          }
        }
        await _repository.create(warga);
        emit(const WargaSaved('Data warga berhasil ditambahkan'));
      }
    } catch (e) {
      emit(WargaError(e.toString()));
    }
  }

  Future<void> delete(int id) async {
    try {
      await _repository.delete(id);
      emit(WargaDeleted());
    } catch (e) {
      emit(WargaError(e.toString()));
    }
  }
}
