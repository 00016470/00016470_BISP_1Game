import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure({required this.message});

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure({required super.message, this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? 0];
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Cannot reach server. Check your connection and make sure the backend is running.',
  });
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}

class ConflictFailure extends Failure {
  const ConflictFailure({required super.message});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.message});
}
