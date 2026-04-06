import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/booking.dart';
import '../repositories/bookings_repository.dart';

class CancelBookingUseCase implements UseCase<Booking, CancelBookingParams> {
  final BookingsRepository repository;
  CancelBookingUseCase(this.repository);

  @override
  Future<Either<Failure, Booking>> call(CancelBookingParams params) {
    return repository.cancelBooking(params.id);
  }
}

class CancelBookingParams extends Equatable {
  final int id;
  const CancelBookingParams({required this.id});

  @override
  List<Object> get props => [id];
}
