import 'package:equatable/equatable.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();
  @override
  List<Object?> get props => [];
}

class AdminDashboardLoadRequested extends AdminEvent {
  const AdminDashboardLoadRequested();
}

class AdminPendingPaymentsLoadRequested extends AdminEvent {
  const AdminPendingPaymentsLoadRequested();
}

class AdminBookingsLoadRequested extends AdminEvent {
  final int? clubId;
  const AdminBookingsLoadRequested({this.clubId});
  @override
  List<Object?> get props => [clubId];
}

class AdminClubsLoadRequested extends AdminEvent {
  const AdminClubsLoadRequested();
}

class AdminCreateClubRequested extends AdminEvent {
  final String name;
  final String location;
  final String description;
  final int pricePerHour;
  final int totalComputers;
  final int openingHour;
  final int closingHour;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  const AdminCreateClubRequested({
    required this.name,
    required this.location,
    required this.description,
    required this.pricePerHour,
    required this.totalComputers,
    required this.openingHour,
    required this.closingHour,
    this.address,
    this.latitude,
    this.longitude,
    this.imageUrl,
  });
  @override
  List<Object?> get props => [name, pricePerHour];
}

class AdminUpdateClubRequested extends AdminEvent {
  final int clubId;
  final Map<String, dynamic> fields;
  const AdminUpdateClubRequested(this.clubId, this.fields);
  @override
  List<Object?> get props => [clubId];
}

class AdminUsersLoadRequested extends AdminEvent {
  final bool pendingOnly;
  const AdminUsersLoadRequested({this.pendingOnly = false});
  @override
  List<Object?> get props => [pendingOnly];
}

class AdminCreateUserRequested extends AdminEvent {
  final String username;
  final String email;
  final String password;
  final String phone;
  const AdminCreateUserRequested({
    required this.username,
    required this.email,
    required this.password,
    required this.phone,
  });
  @override
  List<Object?> get props => [email];
}

class AdminApproveUserRequested extends AdminEvent {
  final int userId;
  const AdminApproveUserRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class AdminRejectUserRequested extends AdminEvent {
  final int userId;
  const AdminRejectUserRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class AdminDeleteUserRequested extends AdminEvent {
  final int userId;
  const AdminDeleteUserRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class AdminUserDetailLoadRequested extends AdminEvent {
  final int userId;
  const AdminUserDetailLoadRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class AdminClubSessionsLoadRequested extends AdminEvent {
  final int clubId;
  const AdminClubSessionsLoadRequested(this.clubId);
  @override
  List<Object?> get props => [clubId];
}

class AdminClubRevenueLoadRequested extends AdminEvent {
  final int clubId;
  const AdminClubRevenueLoadRequested(this.clubId);
  @override
  List<Object?> get props => [clubId];
}

class AdminMultiClubRevenueLoadRequested extends AdminEvent {
  final List<int> clubIds;
  const AdminMultiClubRevenueLoadRequested(this.clubIds);
  @override
  List<Object?> get props => [clubIds];
}

class AdminPaymentValidateRequested extends AdminEvent {
  final int paymentId;
  const AdminPaymentValidateRequested(this.paymentId);
  @override
  List<Object?> get props => [paymentId];
}
