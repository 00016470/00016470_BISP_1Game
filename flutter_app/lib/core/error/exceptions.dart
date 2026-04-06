class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException({
    this.message = 'Cannot reach server. Check your connection and make sure the backend is running.',
  });

  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  final String message;
  const AuthException({required this.message});

  @override
  String toString() => 'AuthException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class ConflictException implements Exception {
  final String message;
  const ConflictException({required this.message});

  @override
  String toString() => 'ConflictException: $message';
}
