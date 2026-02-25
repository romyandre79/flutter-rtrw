import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/data/models/rumah.dart';
import 'package:flutter_pos/data/repositories/rumah_repository.dart';
import 'package:flutter_pos/logic/cubits/rumah/rumah_state.dart';

class RumahCubit extends Cubit<RumahState> {
  final RumahRepository _repository;

  RumahCubit({RumahRepository? repository})
      : _repository = repository ?? RumahRepository(),
        super(RumahInitial());

  Future<void> loadAll({String? search, String? blok}) async {
    emit(RumahLoading());
    try {
      final list = await _repository.getAll(search: search, blok: blok);
      final count = await _repository.getCount();
      emit(RumahLoaded(rumahList: list, totalCount: count));
    } catch (e) {
      emit(RumahError(e.toString()));
    }
  }

  Future<void> save(Rumah rumah) async {
    try {
      if (rumah.id != null) {
        await _repository.update(rumah);
        emit(const RumahSaved('Data rumah berhasil diperbarui'));
      } else {
        await _repository.create(rumah);
        emit(const RumahSaved('Data rumah berhasil ditambahkan'));
      }
    } catch (e) {
      emit(RumahError(e.toString()));
    }
  }

  Future<void> delete(int id) async {
    try {
      await _repository.delete(id);
      emit(RumahDeleted());
    } catch (e) {
      emit(RumahError(e.toString()));
    }
  }
}
