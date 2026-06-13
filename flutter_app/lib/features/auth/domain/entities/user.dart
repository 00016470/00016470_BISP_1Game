import 'package:equatable/equatable.dart';

/// Represents a user in the gaming club application.
/// Contains user profile information, role, and booking statistics.
/// Extends Equatable for proper comparison in state management and testing.
class User extends Equatable {
  /// The unique identifier for the user.
  final int id;

  /// The username chosen by the user.
  final String username;

  /// The email address of the user.
  final String email;

  /// The phone number of the user.
  final String phone;

  /// The total number of bookings made by the user (optional).
  final int? totalBookings;

  /// The date when the user joined the platform (optional, ISO format).
  final String? joinedAt;

  /// The role of the user in the system (e.g., 'user', 'admin').
  final String role;

  /// Whether the user's account has been approved by administrators.
  final bool isApproved;

  /// Creates a User instance with the given properties.
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

  /// Returns true if the user has administrative privileges.
  /// Checks for various admin role types including admin, super_admin, club_admin, and moderator.
  bool get isAdmin {
    final r = role.toLowerCase();
    return r == 'admin' || r == 'super_admin' || r == 'club_admin' || r == 'moderator';
  }

  @override
  List<Object?> get props =>
      [id, username, email, phone, totalBookings, joinedAt, role, isApproved];
}
