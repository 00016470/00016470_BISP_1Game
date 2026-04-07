import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/admin_stats.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;
  AdminRepositoryImpl({required this.remoteDataSource});

  Future<Either<Failure, T>> _call<T>(Future<T> Function() fn) async {
    try {
      return Right(await fn());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, AdminStats>> getDashboard() => _call(() => remoteDataSource.getDashboard());

  @override
  Future<Either<Failure, List<AdminClubItem>>> getClubs() => _call(() => remoteDataSource.getClubs());

  @override
  Future<Either<Failure, AdminClubItem>> createClub(Map<String, dynamic> data) =>
      _call(() => remoteDataSource.createClub(data));

  @override
  Future<Either<Failure, AdminClubItem>> updateClub(int clubId, Map<String, dynamic> data) =>
      _call(() => remoteDataSource.updateClub(clubId, data));

  @override
  Future<Either<Failure, List<AdminUserItem>>> getUsers({bool pendingOnly = false}) =>
      _call(() => remoteDataSource.getUsers(pendingOnly: pendingOnly));

  @override
  Future<Either<Failure, AdminUserItem>> createUser(Map<String, dynamic> data) =>
      _call(() => remoteDataSource.createUser(data));

  @override
  Future<Either<Failure, AdminUserItem>> approveUser(int userId) =>
      _call(() => remoteDataSource.approveUser(userId));

  @override
  Future<Either<Failure, void>> rejectUser(int userId) =>
      _call(() => remoteDataSource.rejectUser(userId));

  @override
  Future<Either<Failure, void>> deleteUser(int userId) =>
      _call(() => remoteDataSource.deleteUser(userId));

  @override
  Future<Either<Failure, AdminUserDetail>> getUserDetail(int userId) =>
      _call(() => remoteDataSource.getUserDetail(userId));

  @override
  Future<Either<Failure, List<AdminBookingItem>>> getBookings({int? clubId}) =>
      _call(() => remoteDataSource.getBookings(clubId: clubId));

  @override
  Future<Either<Failure, List<AdminPaymentItem>>> getPendingPayments() =>
      _call(() => remoteDataSource.getPendingPayments());

  @override
  Future<Either<Failure, AdminPaymentItem>> validatePayment(int id) =>
      _call(() => remoteDataSource.validatePayment(id));

  @override
  Future<Either<Failure, ClubSessions>> getClubSessions(int clubId) =>
      _call(() => remoteDataSource.getClubSessions(clubId));

  @override
  Future<Either<Failure, ClubRevenue>> getClubRevenue(int clubId) =>
      _call(() => remoteDataSource.getClubRevenue(clubId));
}
