import 'package:equatable/equatable.dart';

class RevenueByDay extends Equatable {
  final String date;
  final double revenue;
  final int bookingCount;
  const RevenueByDay({required this.date, required this.revenue, required this.bookingCount});
  @override
  List<Object?> get props => [date, revenue, bookingCount];
}

class BookingsByClub extends Equatable {
  final int clubId;
  final String clubName;
  final int bookingCount;
  final double revenue;
  const BookingsByClub({required this.clubId, required this.clubName, required this.bookingCount, required this.revenue});
  @override
  List<Object?> get props => [clubId, bookingCount];
}

class AdminStats extends Equatable {
  final double totalRevenueToday;
  final int activeBookings;
  final int pendingPayments;
  final int totalUsers;
  final int pendingUsers;
  final List<BookingsByClub> bookingsByClub;
  final List<RevenueByDay> revenueByDay;

  const AdminStats({
    required this.totalRevenueToday,
    required this.activeBookings,
    required this.pendingPayments,
    required this.totalUsers,
    required this.pendingUsers,
    required this.bookingsByClub,
    required this.revenueByDay,
  });

  @override
  List<Object?> get props => [totalRevenueToday, activeBookings, pendingPayments, totalUsers, pendingUsers];
}

class AdminClubItem extends Equatable {
  final int id;
  final String name;
  final String location;
  final int pricePerHour;
  final int totalComputers;
  final double rating;
  final bool isActive;
  final int openingHour;
  final int closingHour;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final int bookingCount;
  final double revenue;

  const AdminClubItem({
    required this.id, required this.name, required this.location,
    required this.pricePerHour, required this.totalComputers,
    required this.rating, required this.isActive,
    required this.openingHour, required this.closingHour,
    this.address, this.latitude, this.longitude, this.imageUrl,
    this.bookingCount = 0, this.revenue = 0,
  });

  @override
  List<Object?> get props => [id, name];
}

class AdminUserItem extends Equatable {
  final int id;
  final String username;
  final String email;
  final String phone;
  final bool isApproved;
  final int bookingCount;
  final double totalSpent;
  final double walletBalance;
  final String joinedAt;

  const AdminUserItem({
    required this.id, required this.username, required this.email,
    required this.phone, required this.isApproved,
    required this.bookingCount, required this.totalSpent,
    required this.walletBalance, required this.joinedAt,
  });

  @override
  List<Object?> get props => [id, username, isApproved];
}

class AdminUserDetail extends Equatable {
  final int id;
  final String username;
  final String email;
  final String? phone;
  final bool isApproved;
  final String joinedAt;
  final double walletBalance;
  final String currency;
  final double totalSpent;
  final int bookingCount;
  final List<Map<String, dynamic>> bookings;
  final List<Map<String, dynamic>> payments;
  final List<Map<String, dynamic>> transactions;

  const AdminUserDetail({
    required this.id, required this.username, required this.email,
    this.phone, required this.isApproved, required this.joinedAt,
    required this.walletBalance, required this.currency,
    required this.totalSpent, required this.bookingCount,
    required this.bookings, required this.payments, required this.transactions,
  });

  @override
  List<Object?> get props => [id, username, isApproved];
}

class AdminBookingItem extends Equatable {
  final int id;
  final int userId;
  final String username;
  final int clubId;
  final String clubName;
  final DateTime startTime;
  final double durationHours;
  final int computersBooked;
  final double totalPrice;
  final String status;
  final String? paymentMethod;
  final String? paymentStatus;
  final DateTime createdAt;

  const AdminBookingItem({
    required this.id, required this.userId, required this.username,
    required this.clubId, required this.clubName,
    required this.startTime, required this.durationHours,
    required this.computersBooked, required this.totalPrice,
    required this.status, this.paymentMethod, this.paymentStatus,
    required this.createdAt,
  });

  DateTime get endTime => startTime.add(Duration(minutes: (durationHours * 60).round()));

  @override
  List<Object?> get props => [id, status];
}

class AdminPaymentItem extends Equatable {
  final int id;
  final int userId;
  final String username;
  final int bookingId;
  final String clubName;
  final double amount;
  final String method;
  final String status;
  final DateTime createdAt;

  const AdminPaymentItem({
    required this.id, required this.userId, required this.username,
    required this.bookingId, required this.clubName,
    required this.amount, required this.method, required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, status];
}

class ClubSessionItem extends Equatable {
  final int bookingId;
  final int userId;
  final String username;
  final int computersBooked;
  final DateTime startTime;
  final DateTime endTime;
  final double remainingMinutes;
  final double? totalPrice;
  final String status;

  const ClubSessionItem({
    required this.bookingId, required this.userId, required this.username,
    required this.computersBooked, required this.startTime,
    required this.endTime, required this.remainingMinutes,
    this.totalPrice, required this.status,
  });

  @override
  List<Object?> get props => [bookingId, status, remainingMinutes];
}

class ClubSessions extends Equatable {
  final int clubId;
  final String clubName;
  final int totalComputers;
  final List<ClubSessionItem> activeSessions;
  final List<ClubSessionItem> upcomingSessions;
  final int availableComputers;

  const ClubSessions({
    required this.clubId, required this.clubName,
    required this.totalComputers, required this.activeSessions,
    required this.upcomingSessions, required this.availableComputers,
  });

  @override
  List<Object?> get props => [clubId, activeSessions.length];
}

class ClubRevenue extends Equatable {
  final int clubId;
  final String clubName;
  final double totalRevenue;
  final int totalSessions;
  final int activeSessions;
  final List<RevenueByDay> revenueByDay;
  final List<ClubSessionItem> recentSessions;

  const ClubRevenue({
    required this.clubId, required this.clubName,
    required this.totalRevenue, required this.totalSessions,
    required this.activeSessions, required this.revenueByDay,
    required this.recentSessions,
  });

  @override
  List<Object?> get props => [clubId, totalRevenue];
}
