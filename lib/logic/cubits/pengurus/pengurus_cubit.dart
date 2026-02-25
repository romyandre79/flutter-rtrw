import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/data/models/pengurus.dart';
import 'package:flutter_pos/data/repositories/pengurus_repository.dart';
import 'package:flutter_pos/logic/cubits/pengurus/pengurus_state.dart';

class PengurusCubit extends Cubit<PengurusState> {
  final PengurusRepository _repository;

  PengurusCubit({PengurusRepository? repository})
      : _repository = repository ?? PengurusRepository(),
        super(PengurusInitial());

  Future<void> loadAll({String? status}) async {
    emit(PengurusLoading());
    try {
      final list = await _repository.getAll(status: status);
      final activeCount = await _repository.getActiveCount();
      emit(PengurusLoaded(pengurusList: list, activeCount: activeCount));
    } catch (e) {
      emit(PengurusError(e.toString()));
    }
  }

  Future<void> save(Pengurus pengurus) async {
    try {
      if (pengurus.id != null) {
        await _repository.update(pengurus);
        emit(const PengurusSaved('Data pengurus berhasil diperbarui'));
      } else {
        await _repository.create(pengurus);
        emit(const PengurusSaved('Data pengurus berhasil ditambahkan'));
      }
    } catch (e) {
      emit(PengurusError(e.toString()));
    }
  }

  Future<void> delete(int id) async {
    try {
      await _repository.delete(id);
      emit(PengurusDeleted());
    } catch (e) {
      emit(PengurusError(e.toString()));
    }
  }
}
