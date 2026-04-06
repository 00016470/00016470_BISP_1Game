import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase implements UseCase<Map<String, dynamic>, RegisterParams> {
  final AuthRepository repository;
  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(RegisterParams params) {
    return repository.register(
      username: params.username,
      email: params.email,
      password: params.password,
      phone: params.phone,
    );
  }
}

class RegisterParams extends Equatable {
  final String username;
  final String email;
  final String password;
  final String phone;

  const RegisterParams({
    required this.username,
    required this.email,
    required this.password,
    required this.phone,
  });

  @override
  List<Object> get props => [username, email, password, phone];
}
