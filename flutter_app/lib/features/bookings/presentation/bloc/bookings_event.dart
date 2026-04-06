import 'package:equatable/equatable.dart';

abstract class BookingsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class BookingsLoadRequested extends BookingsEvent {}

class BookingCreateRequested extends BookingsEvent {
  final int clubSlot;
  final int computersCount;
  final int durationHours;

  BookingCreateRequested({
    required this.clubSlot,
    required this.computersCount,
    required this.durationHours,
  });

  @override
  List<Object> get props => [clubSlot, computersCount, durationHours];
}

class BookingCancelRequested extends BookingsEvent {
  final int bookingId;
  BookingCancelRequested(this.bookingId);

  @override
  List<Object> get props => [bookingId];
}
