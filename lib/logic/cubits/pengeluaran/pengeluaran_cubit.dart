import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/constants/app_constants.dart';
import 'package:flutter_pos/data/models/pengeluaran.dart';
import 'package:flutter_pos/data/repositories/pengeluaran_repository.dart';
import 'package:flutter_pos/logic/cubits/pengeluaran/pengeluaran_state.dart';

class PengeluaranCubit extends Cubit<PengeluaranState> {
  final PengeluaranRepository _repository;

  PengeluaranCubit({PengeluaranRepository? repository})
      : _repository = repository ?? PengeluaranRepository(),
        super(PengeluaranInitial());

  Future<void> loadAll({String? kategori}) async {
    emit(PengeluaranLoading());
    try {
      final list = await _repository.getAll(kategori: kategori);
      double total = 0;
      for (final p in list) {
        total += p.jumlah;
      }
      emit(PengeluaranLoaded(pengeluaranList: list, totalPengeluaran: total));
    } catch (e) {
      emit(PengeluaranError(e.toString()));
    }
  }

  Future<void> save(Pengeluaran pengeluaran) async {
    try {
      if (pengeluaran.id != null) {
        await _repository.update(pengeluaran);
        emit(const PengeluaranSaved('Data pengeluaran berhasil diperbarui'));
      } else {
        if (AppConstants.isDemo) {
          final count = await _repository.getCount();
          if (count >= 10) {
            emit(const PengeluaranError('Anda telah melebihi batas transaksi aplikasi demo, silakan beli hubungi Sales Kreatif atau ke 081932701147'));
            return;
          }
        }
        await _repository.create(pengeluaran);
        emit(const PengeluaranSaved('Data pengeluaran berhasil ditambahkan'));
      }
    } catch (e) {
      emit(PengeluaranError(e.toString()));
    }
  }

  Future<void> delete(int id) async {
    try {
      await _repository.delete(id);
      emit(PengeluaranDeleted());
    } catch (e) {
      emit(PengeluaranError(e.toString()));
    }
  }
}
