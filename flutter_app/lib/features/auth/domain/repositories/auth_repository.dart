import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

/// Abstract repository interface for authentication operations.
/// Defines the contract for authentication-related data operations.
/// All methods return Either<Failure, T> to handle both success and error cases.
abstract class AuthRepository {
  /// Authenticates a user with email and password.
  /// Returns a map containing access and refresh tokens on success.
  /// [email] The user's email address.
  /// [password] The user's password.
  Future<Either<Failure, Map<String, dynamic>>> login({
    required String email,
    required String password,
  });

  /// Registers a new user account.
  /// Returns a map containing access and refresh tokens on success.
  /// [username] The desired username.
  /// [email] The user's email address.
  /// [password] The user's password.
  /// [phone] The user's phone number.
  Future<Either<Failure, Map<String, dynamic>>> register({
    required String username,
    required String email,
    required String password,
    required String phone,
  });

  /// Refreshes an access token using a refresh token.
  /// Returns a new access token on success.
  /// [refreshToken] The refresh token to use for renewal.
  Future<Either<Failure, String>> refreshToken(String refreshToken);

  /// Logs out the current user by clearing stored tokens.
  /// Returns void on success.
  Future<Either<Failure, void>> logout();

  /// Retrieves the current authenticated user's profile information.
  /// Returns a User object on success.
  Future<Either<Failure, User>> getCurrentUser();

  /// Checks if a user is currently logged in.
  /// Returns true if valid tokens exist, false otherwise.
  Future<bool> isLoggedIn();
}
