import 'package:equatable/equatable.dart';
import '../../domain/entities/booking.dart';

abstract class BookingsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BookingsInitial extends BookingsState {}

class BookingsLoading extends BookingsState {}

class BookingsLoaded extends BookingsState {
  final List<Booking> bookings;
  final List<Booking> upcomingBookings;
  final List<Booking> pastBookings;

  BookingsLoaded(this.bookings)
      : upcomingBookings = bookings.where((b) => b.isUpcoming).toList(),
        pastBookings = bookings.where((b) => b.isPast).toList();

  @override
  List<Object> get props => [bookings];
}

class BookingCreating extends BookingsState {}

class BookingCreated extends BookingsState {
  final Booking booking;
  BookingCreated(this.booking);

  @override
  List<Object> get props => [booking];
}

class BookingCancelling extends BookingsState {
  final int bookingId;
  BookingCancelling(this.bookingId);

  @override
  List<Object> get props => [bookingId];
}

class BookingsError extends BookingsState {
  final String message;
  BookingsError(this.message);

  @override
  List<Object> get props => [message];
}

class BookingActionError extends BookingsState {
  final String message;
  final List<Booking>? bookings;
  BookingActionError(this.message, {this.bookings});

  @override
  List<Object?> get props => [message, bookings];
}
