import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../datasources/bookings_remote_datasource.dart';

class BookingsRepositoryImpl implements BookingsRepository {
  final BookingsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  BookingsRepositoryImpl(
      {required this.remoteDataSource, required this.networkInfo});

  @override
  Future<Either<Failure, Booking>> createBooking({
    required int clubId,
    required String startTime,
    required int computersCount,
    required int durationHours,
    String paymentMethod = 'WALLET',
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final booking = await remoteDataSource.createBooking(
        clubId: clubId,
        startTime: startTime,
        computersCount: computersCount,
        durationHours: durationHours,
        paymentMethod: paymentMethod,
      );
      return Right(booking);
    } on ConflictException catch (e) {
      return Left(ConflictFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, List<Booking>>> getBookings() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final bookings = await remoteDataSource.getBookings();
      return Right(bookings);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, Booking>> cancelBooking(int id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final booking = await remoteDataSource.cancelBooking(id);
      return Right(booking);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
