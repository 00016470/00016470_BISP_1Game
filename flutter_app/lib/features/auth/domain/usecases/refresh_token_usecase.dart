import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class RefreshTokenUseCase implements UseCase<String, RefreshTokenParams> {
  final AuthRepository repository;
  RefreshTokenUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(RefreshTokenParams params) {
    return repository.refreshToken(params.refreshToken);
  }
}

class RefreshTokenParams extends Equatable {
  final String refreshToken;
  const RefreshTokenParams({required this.refreshToken});

  @override
  List<Object> get props => [refreshToken];
}
