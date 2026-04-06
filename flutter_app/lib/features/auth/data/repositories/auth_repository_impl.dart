import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../config/constants.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final FlutterSecureStorage secureStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
  });

  @override
  Future<Either<Failure, Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result =
          await remoteDataSource.login(email: email, password: password);
      await secureStorage.write(
          key: AppConstants.accessTokenKey,
          value: result['access'] as String);
      await secureStorage.write(
          key: AppConstants.refreshTokenKey,
          value: result['refresh'] as String);
      return Right(result);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> register({
    required String username,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final result = await remoteDataSource.register(
        username: username,
        email: email,
        password: password,
        phone: phone,
      );
      await secureStorage.write(
          key: AppConstants.accessTokenKey,
          value: result['access'] as String);
      await secureStorage.write(
          key: AppConstants.refreshTokenKey,
          value: result['refresh'] as String);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, String>> refreshToken(String token) async {
    try {
      final newToken = await remoteDataSource.refreshToken(token);
      await secureStorage.write(
          key: AppConstants.accessTokenKey, value: newToken);
      return Right(newToken);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (_) {}
    await secureStorage.deleteAll();
    return const Right(null);
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token =
        await secureStorage.read(key: AppConstants.accessTokenKey);
    return token != null && token.isNotEmpty;
  }
}
