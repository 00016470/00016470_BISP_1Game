import 'package:equatable/equatable.dart';
import '../../domain/entities/club.dart';
import '../../domain/entities/slot.dart';

abstract class ClubDetailState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ClubDetailInitial extends ClubDetailState {}

class ClubDetailLoading extends ClubDetailState {}

class ClubDetailLoaded extends ClubDetailState {
  final Club club;
  final List<Slot> slots;
  final bool slotsLoading;
  final String selectedDate;

  ClubDetailLoaded({
    required this.club,
    required this.slots,
    this.slotsLoading = false,
    required this.selectedDate,
  });

  ClubDetailLoaded copyWith({
    Club? club,
    List<Slot>? slots,
    bool? slotsLoading,
    String? selectedDate,
  }) {
    return ClubDetailLoaded(
      club: club ?? this.club,
      slots: slots ?? this.slots,
      slotsLoading: slotsLoading ?? this.slotsLoading,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }

  @override
  List<Object> get props => [club, slots, slotsLoading, selectedDate];
}

class ClubDetailError extends ClubDetailState {
  final String message;
  ClubDetailError(this.message);

  @override
  List<Object> get props => [message];
}
