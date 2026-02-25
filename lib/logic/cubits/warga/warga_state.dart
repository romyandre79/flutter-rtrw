import 'package:equatable/equatable.dart';
import 'package:flutter_pos/data/models/warga.dart';

abstract class WargaState extends Equatable {
  const WargaState();
  @override
  List<Object?> get props => [];
}

class WargaInitial extends WargaState {}

class WargaLoading extends WargaState {}

class WargaLoaded extends WargaState {
  final List<Warga> wargaList;
  final int totalCount;

  const WargaLoaded({required this.wargaList, this.totalCount = 0});

  @override
  List<Object?> get props => [wargaList, totalCount];
}

class WargaDetailLoaded extends WargaState {
  final Warga warga;

  const WargaDetailLoaded(this.warga);

  @override
  List<Object?> get props => [warga];
}

class WargaSaved extends WargaState {
  final String message;
  const WargaSaved(this.message);
}

class WargaDeleted extends WargaState {}

class WargaError extends WargaState {
  final String message;
  const WargaError(this.message);

  @override
  List<Object?> get props => [message];
}
