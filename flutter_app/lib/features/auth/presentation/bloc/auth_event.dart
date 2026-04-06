import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;
  final String phone;

  AuthRegisterRequested({
    required this.username,
    required this.email,
    required this.password,
    required this.phone,
  });

  @override
  List<Object> get props => [username, email, password, phone];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthGuestModeEntered extends AuthEvent {}
