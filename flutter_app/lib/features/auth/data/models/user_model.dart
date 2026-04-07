import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    required super.email,
    required super.phone,
    super.totalBookings,
    super.joinedAt,
    super.role,
    super.isApproved,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      totalBookings: json['total_bookings'] as int?,
      joinedAt: json['joined_at'] as String?,
      role: json['role'] as String? ?? 'user',
      isApproved: json['is_approved'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'phone': phone,
        'total_bookings': totalBookings,
        'joined_at': joinedAt,
        'role': role,
        'is_approved': isApproved,
      };
}
