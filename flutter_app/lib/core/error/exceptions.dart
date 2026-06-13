/// Exception thrown when the server returns an error response.
/// Contains the error message and optional HTTP status code.
class ServerException implements Exception {
  /// The error message from the server.
  final String message;

  /// The HTTP status code, if available.
  final int? statusCode;

  /// Creates a ServerException with the given message and status code.
  const ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

/// Exception thrown when there is a network connectivity issue.
/// Typically occurs when the device cannot reach the server.
class NetworkException implements Exception {
  /// The error message describing the network issue.
  final String message;

  /// Creates a NetworkException with an optional custom message.
  const NetworkException({
    this.message = 'Cannot reach server. Check your connection and make sure the backend is running.',
  });

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception thrown when authentication fails.
/// Used for login, token refresh, and other auth-related errors.
class AuthException implements Exception {
  /// The error message describing the authentication failure.
  final String message;

  /// Creates an AuthException with the given message.
  const AuthException({required this.message});

  @override
  String toString() => 'AuthException: $message';
}

/// Exception thrown when there is an issue with cached data.
/// Used for cache read/write operations that fail.
class CacheException implements Exception {
  /// The error message describing the cache issue.
  final String message;

  /// Creates a CacheException with the given message.
  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

/// Exception thrown when there is a conflict in the operation.
/// Typically used for booking conflicts or resource conflicts.
class ConflictException implements Exception {
  /// The error message describing the conflict.
  final String message;

  /// Creates a ConflictException with the given message.
  const ConflictException({required this.message});

  @override
  String toString() => 'ConflictException: $message';
}
