import 'package:equatable/equatable.dart';
import 'package:flutter_pos/data/models/pengurus.dart';

abstract class PengurusState extends Equatable {
  const PengurusState();
  @override
  List<Object?> get props => [];
}

class PengurusInitial extends PengurusState {}

class PengurusLoading extends PengurusState {}

class PengurusLoaded extends PengurusState {
  final List<Pengurus> pengurusList;
  final int activeCount;

  const PengurusLoaded({required this.pengurusList, this.activeCount = 0});

  @override
  List<Object?> get props => [pengurusList, activeCount];
}

class PengurusSaved extends PengurusState {
  final String message;
  const PengurusSaved(this.message);
}

class PengurusDeleted extends PengurusState {}

class PengurusError extends PengurusState {
  final String message;
  const PengurusError(this.message);

  @override
  List<Object?> get props => [message];
}
