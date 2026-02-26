import 'package:equatable/equatable.dart';
import 'package:flutter_pos/data/models/iuran.dart';

abstract class IuranState extends Equatable {
  const IuranState();
  @override
  List<Object?> get props => [];
}

class IuranInitial extends IuranState {}

class IuranLoading extends IuranState {}

class IuranLoaded extends IuranState {
  final List<Iuran> iuranList;
  final double totalLunas;
  final double totalBelumBayar;

  const IuranLoaded({
    required this.iuranList,
    this.totalLunas = 0,
    this.totalBelumBayar = 0,
  });

  @override
  List<Object?> get props => [iuranList, totalLunas, totalBelumBayar];
}

class IuranSaved extends IuranState {
  final String message;
  const IuranSaved(this.message);
}

class IuranDeleted extends IuranState {}

class IuranError extends IuranState {
  final String message;
  const IuranError(this.message);

  @override
  List<Object?> get props => [message];
}
