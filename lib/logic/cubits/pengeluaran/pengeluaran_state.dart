import 'package:equatable/equatable.dart';
import 'package:flutter_pos/data/models/pengeluaran.dart';

abstract class PengeluaranState extends Equatable {
  const PengeluaranState();
  @override
  List<Object?> get props => [];
}

class PengeluaranInitial extends PengeluaranState {}

class PengeluaranLoading extends PengeluaranState {}

class PengeluaranLoaded extends PengeluaranState {
  final List<Pengeluaran> pengeluaranList;
  final double totalPengeluaran;

  const PengeluaranLoaded({
    required this.pengeluaranList,
    this.totalPengeluaran = 0,
  });

  @override
  List<Object?> get props => [pengeluaranList, totalPengeluaran];
}

class PengeluaranSaved extends PengeluaranState {
  final String message;
  const PengeluaranSaved(this.message);
}

class PengeluaranDeleted extends PengeluaranState {}

class PengeluaranError extends PengeluaranState {
  final String message;
  const PengeluaranError(this.message);

  @override
  List<Object?> get props => [message];
}
