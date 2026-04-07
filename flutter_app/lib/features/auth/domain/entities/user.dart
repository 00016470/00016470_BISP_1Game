import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String username;
  final String email;
  final String phone;
  final int? totalBookings;
  final String? joinedAt;
  final String role;
  final bool isApproved;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    this.totalBookings,
    this.joinedAt,
    this.role = 'user',
    this.isApproved = true,
  });

  bool get isAdmin {
    final r = role.toLowerCase();
    return r == 'admin' || r == 'super_admin' || r == 'club_admin' || r == 'moderator';
  }

  @override
  List<Object?> get props =>
      [id, username, email, phone, totalBookings, joinedAt, role, isApproved];
}
