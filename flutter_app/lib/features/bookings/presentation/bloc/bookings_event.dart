import 'package:equatable/equatable.dart';

abstract class BookingsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class BookingsLoadRequested extends BookingsEvent {}

class BookingCreateRequested extends BookingsEvent {
  final int clubId;
  final String startTime; // ISO-8601 datetime, e.g. "2026-04-09T14:00:00Z"
  final int computersCount;
  final int durationHours;
  final String paymentMethod;

  BookingCreateRequested({
    required this.clubId,
    required this.startTime,
    required this.computersCount,
    required this.durationHours,
    this.paymentMethod = 'WALLET',
  });

  @override
  List<Object> get props => [clubId, startTime, computersCount, durationHours, paymentMethod];
}

class BookingCancelRequested extends BookingsEvent {
  final int bookingId;
  BookingCancelRequested(this.bookingId);

  @override
  List<Object> get props => [bookingId];
}
