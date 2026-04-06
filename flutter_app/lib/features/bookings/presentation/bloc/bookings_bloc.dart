import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/booking.dart';
import '../../domain/usecases/create_booking_usecase.dart';
import '../../domain/usecases/get_bookings_usecase.dart';
import '../../domain/usecases/cancel_booking_usecase.dart';
import '../../../../core/usecases/usecase.dart';
import 'bookings_event.dart';
import 'bookings_state.dart';

class BookingsBloc extends Bloc<BookingsEvent, BookingsState> {
  final CreateBookingUseCase createBookingUseCase;
  final GetBookingsUseCase getBookingsUseCase;
  final CancelBookingUseCase cancelBookingUseCase;

  List<Booking> _currentBookings = [];

  BookingsBloc({
    required this.createBookingUseCase,
    required this.getBookingsUseCase,
    required this.cancelBookingUseCase,
  }) : super(BookingsInitial()) {
    on<BookingsLoadRequested>(_onLoadRequested);
    on<BookingCreateRequested>(_onCreateRequested);
    on<BookingCancelRequested>(_onCancelRequested);
  }

  Future<void> _onLoadRequested(
      BookingsLoadRequested event, Emitter<BookingsState> emit) async {
    emit(BookingsLoading());
    final result = await getBookingsUseCase(NoParams());
    result.fold(
      (failure) => emit(BookingsError(failure.message)),
      (bookings) {
        _currentBookings = bookings;
        emit(BookingsLoaded(bookings));
      },
    );
  }

  Future<void> _onCreateRequested(
      BookingCreateRequested event, Emitter<BookingsState> emit) async {
    emit(BookingCreating());
    final result = await createBookingUseCase(CreateBookingParams(
      clubSlot: event.clubSlot,
      computersCount: event.computersCount,
      durationHours: event.durationHours,
    ));
    result.fold(
      (failure) => emit(BookingActionError(failure.message,
          bookings: _currentBookings)),
      (booking) {
        _currentBookings = [booking, ..._currentBookings];
        emit(BookingCreated(booking));
      },
    );
  }

  Future<void> _onCancelRequested(
      BookingCancelRequested event, Emitter<BookingsState> emit) async {
    emit(BookingCancelling(event.bookingId));
    final result = await cancelBookingUseCase(
        CancelBookingParams(id: event.bookingId));
    result.fold(
      (failure) => emit(BookingActionError(failure.message,
          bookings: _currentBookings)),
      (updated) {
        _currentBookings = _currentBookings
            .map((b) => b.id == updated.id ? updated : b)
            .toList();
        emit(BookingsLoaded(_currentBookings));
      },
    );
  }
}
