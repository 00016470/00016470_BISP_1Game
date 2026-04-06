
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaming_club_tashkent/core/error/failures.dart';
import 'package:gaming_club_tashkent/features/auth/domain/repositories/auth_repository.dart';
import 'package:gaming_club_tashkent/features/auth/domain/usecases/login_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    useCase = LoginUseCase(mockRepo);
  });

  test('returns data on success', () async {
    final mockData = {
      'access': 'token',
      'refresh': 'refresh',
      'user': {'id': 1, 'username': 'u', 'email': 'e@e.com', 'phone': ''}
    };
    when(() => mockRepo.login(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async => Right(mockData));

    final result = await useCase(LoginParams(email: 'e@e.com', password: 'pass'));

    expect(result, Right(mockData));
    verify(() => mockRepo.login(email: 'e@e.com', password: 'pass')).called(1);
  });

  test('returns failure on error', () async {
    when(() => mockRepo.login(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer(
            (_) async => const Left(AuthFailure(message: 'Invalid credentials')));

    final result = await useCase(LoginParams(email: 'bad', password: 'bad'));

    expect(result, const Left(AuthFailure(message: 'Invalid credentials')));
  });
}
