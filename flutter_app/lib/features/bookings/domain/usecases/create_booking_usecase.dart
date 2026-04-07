import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/booking.dart';
import '../repositories/bookings_repository.dart';

class CreateBookingUseCase implements UseCase<Booking, CreateBookingParams> {
  final BookingsRepository repository;
  CreateBookingUseCase(this.repository);

  @override
  Future<Either<Failure, Booking>> call(CreateBookingParams params) {
    return repository.createBooking(
      clubId: params.clubId,
      startTime: params.startTime,
      computersCount: params.computersCount,
      durationHours: params.durationHours,
      paymentMethod: params.paymentMethod,
    );
  }
}

class CreateBookingParams extends Equatable {
  final int clubId;
  final String startTime;
  final int computersCount;
  final int durationHours;
  final String paymentMethod;

  const CreateBookingParams({
    required this.clubId,
    required this.startTime,
    required this.computersCount,
    required this.durationHours,
    this.paymentMethod = 'WALLET',
  });

  @override
  List<Object> get props => [clubId, startTime, computersCount, durationHours, paymentMethod];
}
