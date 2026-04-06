import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/booking.dart';

abstract class BookingsRepository {
  Future<Either<Failure, Booking>> createBooking({
    required int clubSlot,
    required int computersCount,
    required int durationHours,
  });
  Future<Either<Failure, List<Booking>>> getBookings();
  Future<Either<Failure, Booking>> cancelBooking(int id);
}
