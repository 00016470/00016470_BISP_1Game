
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaming_club_tashkent/core/error/failures.dart';
import 'package:gaming_club_tashkent/core/usecases/usecase.dart';
import 'package:gaming_club_tashkent/features/bookings/domain/entities/booking.dart';
import 'package:gaming_club_tashkent/features/bookings/domain/usecases/cancel_booking_usecase.dart';
import 'package:gaming_club_tashkent/features/bookings/domain/usecases/create_booking_usecase.dart';
import 'package:gaming_club_tashkent/features/bookings/domain/usecases/get_bookings_usecase.dart';
import 'package:gaming_club_tashkent/features/bookings/presentation/bloc/bookings_bloc.dart';
import 'package:gaming_club_tashkent/features/bookings/presentation/bloc/bookings_event.dart';
import 'package:gaming_club_tashkent/features/bookings/presentation/bloc/bookings_state.dart';

class MockCreateBookingUseCase extends Mock implements CreateBookingUseCase {}
class MockGetBookingsUseCase extends Mock implements GetBookingsUseCase {}
class MockCancelBookingUseCase extends Mock implements CancelBookingUseCase {}

const _testBooking = Booking(
  id: 1,
  clubName: 'Test Club',
  clubLocation: 'Test Location',
  clubId: 1,
  date: '2024-01-15',
  startTime: '10:00:00',
  endTime: '12:00:00',
  computersCount: 2,
  durationHours: 2,
  totalPrice: 40000,
  status: 'confirmed',
  createdAt: '2024-01-01T10:00:00Z',
);

void main() {
  late BookingsBloc bloc;
  late MockCreateBookingUseCase mockCreate;
  late MockGetBookingsUseCase mockGet;
  late MockCancelBookingUseCase mockCancel;

  setUp(() {
    mockCreate = MockCreateBookingUseCase();
    mockGet = MockGetBookingsUseCase();
    mockCancel = MockCancelBookingUseCase();
    bloc = BookingsBloc(
      createBookingUseCase: mockCreate,
      getBookingsUseCase: mockGet,
      cancelBookingUseCase: mockCancel,
    );
    registerFallbackValue(NoParams());
    registerFallbackValue(
        const CreateBookingParams(clubId: 1, startTime: '2024-01-15T10:00:00Z', computersCount: 1, durationHours: 1));
    registerFallbackValue(const CancelBookingParams(id: 1));
  });

  tearDown(() => bloc.close());

  blocTest<BookingsBloc, BookingsState>(
    'emits BookingsLoaded on successful load',
    build: () {
      when(() => mockGet(any()))
          .thenAnswer((_) async => const Right([_testBooking]));
      return bloc;
    },
    act: (b) => b.add(BookingsLoadRequested()),
    expect: () => [isA<BookingsLoading>(), isA<BookingsLoaded>()],
  );

  blocTest<BookingsBloc, BookingsState>(
    'emits BookingCreated on successful create',
    build: () {
      when(() => mockCreate(any()))
          .thenAnswer((_) async => const Right(_testBooking));
      return bloc;
    },
    act: (b) => b.add(BookingCreateRequested(
        clubId: 1, startTime: '2024-01-15T10:00:00Z', computersCount: 2, durationHours: 2)),
    expect: () => [isA<BookingCreating>(), isA<BookingCreated>()],
  );

  blocTest<BookingsBloc, BookingsState>(
    'emits BookingActionError on create failure',
    build: () {
      when(() => mockCreate(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Server error')));
      return bloc;
    },
    act: (b) => b.add(BookingCreateRequested(
        clubId: 1, startTime: '2024-01-15T10:00:00Z', computersCount: 2, durationHours: 2)),
    expect: () => [isA<BookingCreating>(), isA<BookingActionError>()],
  );
}
