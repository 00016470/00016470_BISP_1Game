import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, Map<String, dynamic>>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, Map<String, dynamic>>> register({
    required String username,
    required String email,
    required String password,
    required String phone,
  });

  Future<Either<Failure, String>> refreshToken(String refreshToken);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, User>> getCurrentUser();
  Future<bool> isLoggedIn();
}
