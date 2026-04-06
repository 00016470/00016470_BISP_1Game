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
      clubSlot: params.clubSlot,
      computersCount: params.computersCount,
      durationHours: params.durationHours,
    );
  }
}

class CreateBookingParams extends Equatable {
  final int clubSlot;
  final int computersCount;
  final int durationHours;

  const CreateBookingParams({
    required this.clubSlot,
    required this.computersCount,
    required this.durationHours,
  });

  @override
  List<Object> get props => [clubSlot, computersCount, durationHours];
}
