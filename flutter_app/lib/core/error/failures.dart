import 'package:equatable/equatable.dart';

/// Abstract base class for all application failures.
/// Failures represent domain-level errors that can occur during operations.
/// Extends Equatable for proper comparison in tests and state management.
abstract class Failure extends Equatable {
  /// The error message describing the failure.
  final String message;

  /// Creates a Failure with the given message.
  const Failure({required this.message});

  @override
  List<Object> get props => [message];
}

/// Failure representing a server error response.
/// Contains the error message and optional HTTP status code.
class ServerFailure extends Failure {
  /// The HTTP status code, if available.
  final int? statusCode;

  /// Creates a ServerFailure with message and optional status code.
  const ServerFailure({required super.message, this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? 0];
}

/// Failure representing a network connectivity issue.
/// Occurs when the device cannot reach the server.
class NetworkFailure extends Failure {
  /// Creates a NetworkFailure with an optional custom message.
  const NetworkFailure({
    super.message = 'Cannot reach server. Check your connection and make sure the backend is running.',
  });
}

/// Failure representing an authentication error.
/// Used for login failures, expired tokens, etc.
class AuthFailure extends Failure {
  /// Creates an AuthFailure with the given message.
  const AuthFailure({required super.message});
}

/// Failure representing a cache operation error.
/// Occurs when reading from or writing to cache fails.
class CacheFailure extends Failure {
  /// Creates a CacheFailure with the given message.
  const CacheFailure({required super.message});
}

/// Failure representing validation errors.
/// Used when user input or data validation fails.
class ValidationFailure extends Failure {
  /// Creates a ValidationFailure with the given message.
  const ValidationFailure({required super.message});
}

/// Failure representing a resource conflict.
/// Typically occurs when trying to book an already occupied slot.
class ConflictFailure extends Failure {
  /// Creates a ConflictFailure with the given message.
  const ConflictFailure({required super.message});
}

/// Failure representing a not found error.
/// Occurs when requested resource doesn't exist.
class NotFoundFailure extends Failure {
  /// Creates a NotFoundFailure with the given message.
  const NotFoundFailure({required super.message});
}
