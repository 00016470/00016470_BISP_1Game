import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_stats.dart';

abstract class AdminState extends Equatable {
  const AdminState();
  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {
  const AdminInitial();
}

class AdminLoading extends AdminState {
  const AdminLoading();
}

class AdminDashboardLoaded extends AdminState {
  final AdminStats stats;
  const AdminDashboardLoaded(this.stats);
  @override
  List<Object?> get props => [stats];
}

class AdminClubsLoaded extends AdminState {
  final List<AdminClubItem> clubs;
  const AdminClubsLoaded(this.clubs);
  @override
  List<Object?> get props => [clubs];
}

class AdminClubActionSuccess extends AdminState {
  final String message;
  final AdminClubItem club;
  const AdminClubActionSuccess(this.message, this.club);
  @override
  List<Object?> get props => [message];
}

class AdminUsersLoaded extends AdminState {
  final List<AdminUserItem> users;
  const AdminUsersLoaded(this.users);
  @override
  List<Object?> get props => [users];
}

class AdminUserCreated extends AdminState {
  final AdminUserItem user;
  const AdminUserCreated(this.user);
  @override
  List<Object?> get props => [user];
}

class AdminUserApproved extends AdminState {
  final AdminUserItem user;
  const AdminUserApproved(this.user);
  @override
  List<Object?> get props => [user];
}

class AdminUserRejected extends AdminState {
  final int userId;
  const AdminUserRejected(this.userId);
  @override
  List<Object?> get props => [userId];
}

class AdminUserDeleted extends AdminState {
  final int userId;
  const AdminUserDeleted(this.userId);
  @override
  List<Object?> get props => [userId];
}

class AdminUserDetailLoaded extends AdminState {
  final AdminUserDetail detail;
  const AdminUserDetailLoaded(this.detail);
  @override
  List<Object?> get props => [detail];
}

class AdminBookingsLoaded extends AdminState {
  final List<AdminBookingItem> bookings;
  const AdminBookingsLoaded(this.bookings);
  @override
  List<Object?> get props => [bookings];
}

class AdminPaymentsLoaded extends AdminState {
  final List<AdminPaymentItem> payments;
  const AdminPaymentsLoaded(this.payments);
  @override
  List<Object?> get props => [payments];
}

class AdminPaymentValidated extends AdminState {
  final int paymentId;
  const AdminPaymentValidated(this.paymentId);
  @override
  List<Object?> get props => [paymentId];
}

class AdminClubSessionsLoaded extends AdminState {
  final ClubSessions sessions;
  const AdminClubSessionsLoaded(this.sessions);
  @override
  List<Object?> get props => [sessions];
}

class AdminClubRevenueLoaded extends AdminState {
  final ClubRevenue revenue;
  const AdminClubRevenueLoaded(this.revenue);
  @override
  List<Object?> get props => [revenue];
}

class AdminMultiClubRevenueLoaded extends AdminState {
  final ClubRevenue combinedRevenue;
  final List<int> clubIds;
  const AdminMultiClubRevenueLoaded(this.combinedRevenue, this.clubIds);
  @override
  List<Object?> get props => [combinedRevenue, clubIds];
}

class AdminError extends AdminState {
  final String message;
  const AdminError(this.message);
  @override
  List<Object?> get props => [message];
}
