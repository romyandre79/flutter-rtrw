import 'package:equatable/equatable.dart';
import 'package:flutter_pos/data/models/rumah.dart';

abstract class RumahState extends Equatable {
  const RumahState();
  @override
  List<Object?> get props => [];
}

class RumahInitial extends RumahState {}

class RumahLoading extends RumahState {}

class RumahLoaded extends RumahState {
  final List<Rumah> rumahList;
  final int totalCount;

  const RumahLoaded({required this.rumahList, this.totalCount = 0});

  @override
  List<Object?> get props => [rumahList, totalCount];
}

class RumahSaved extends RumahState {
  final String message;
  const RumahSaved(this.message);
}

class RumahDeleted extends RumahState {}

class RumahError extends RumahState {
  final String message;
  const RumahError(this.message);

  @override
  List<Object?> get props => [message];
}
