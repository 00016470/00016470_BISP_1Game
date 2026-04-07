import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/admin_stats.dart';

abstract class AdminRepository {
  Future<Either<Failure, AdminStats>> getDashboard();
  Future<Either<Failure, List<AdminClubItem>>> getClubs();
  Future<Either<Failure, AdminClubItem>> createClub(Map<String, dynamic> data);
  Future<Either<Failure, AdminClubItem>> updateClub(int clubId, Map<String, dynamic> data);
  Future<Either<Failure, List<AdminUserItem>>> getUsers({bool pendingOnly = false});
  Future<Either<Failure, AdminUserItem>> createUser(Map<String, dynamic> data);
  Future<Either<Failure, AdminUserItem>> approveUser(int userId);
  Future<Either<Failure, void>> rejectUser(int userId);
  Future<Either<Failure, void>> deleteUser(int userId);
  Future<Either<Failure, AdminUserDetail>> getUserDetail(int userId);
  Future<Either<Failure, List<AdminBookingItem>>> getBookings({int? clubId});
  Future<Either<Failure, List<AdminPaymentItem>>> getPendingPayments();
  Future<Either<Failure, AdminPaymentItem>> validatePayment(int paymentId);
  Future<Either<Failure, ClubSessions>> getClubSessions(int clubId);
  Future<Either<Failure, ClubRevenue>> getClubRevenue(int clubId);
}
