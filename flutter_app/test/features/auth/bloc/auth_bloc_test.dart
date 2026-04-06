
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaming_club_tashkent/core/error/failures.dart';
import 'package:gaming_club_tashkent/core/usecases/usecase.dart';
import 'package:gaming_club_tashkent/features/auth/domain/entities/user.dart';
import 'package:gaming_club_tashkent/features/auth/domain/repositories/auth_repository.dart';
import 'package:gaming_club_tashkent/features/auth/domain/usecases/login_usecase.dart';
import 'package:gaming_club_tashkent/features/auth/domain/usecases/logout_usecase.dart';
import 'package:gaming_club_tashkent/features/auth/domain/usecases/register_usecase.dart';
import 'package:gaming_club_tashkent/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gaming_club_tashkent/features/auth/presentation/bloc/auth_event.dart';
import 'package:gaming_club_tashkent/features/auth/presentation/bloc/auth_state.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockRegisterUseCase extends Mock implements RegisterUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockAuthRepository extends Mock implements AuthRepository {}

class _TestUser extends User {
  const _TestUser()
      : super(
            id: 1,
            username: 'testuser',
            email: 'test@test.com',
            phone: '+1234567890');
}

void main() {
  late AuthBloc bloc;
  late MockLoginUseCase mockLogin;
  late MockRegisterUseCase mockRegister;
  late MockLogoutUseCase mockLogout;
  late MockAuthRepository mockRepo;

  setUp(() {
    mockLogin = MockLoginUseCase();
    mockRegister = MockRegisterUseCase();
    mockLogout = MockLogoutUseCase();
    mockRepo = MockAuthRepository();
    bloc = AuthBloc(
      loginUseCase: mockLogin,
      registerUseCase: mockRegister,
      logoutUseCase: mockLogout,
      authRepository: mockRepo,
    );
    registerFallbackValue(LoginParams(email: '', password: ''));
    registerFallbackValue(RegisterParams(
        username: '', email: '', password: '', phone: ''));
    registerFallbackValue(NoParams());
  });

  tearDown(() => bloc.close());

  group('AuthCheckRequested', () {
    test('emits Authenticated when logged in', () async {
      when(() => mockRepo.isLoggedIn()).thenAnswer((_) async => true);
      when(() => mockRepo.getCurrentUser())
          .thenAnswer((_) async => const Right(_TestUser()));
      bloc.add(AuthCheckRequested());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthAuthenticated>(),
        ]),
      );
    });

    test('emits Unauthenticated when not logged in', () async {
      when(() => mockRepo.isLoggedIn()).thenAnswer((_) async => false);
      bloc.add(AuthCheckRequested());
      await expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthUnauthenticated>()]),
      );
    });
  });

  group('AuthLoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits AuthAuthenticated on success',
      build: () {
        when(() => mockLogin(any())).thenAnswer((_) async => Right({
              'access': 'token',
              'refresh': 'refresh',
              'user': {
                'id': 1,
                'username': 'test',
                'email': 'test@test.com',
                'phone': ''
              }
            }));
        return bloc;
      },
      act: (b) =>
          b.add(AuthLoginRequested(email: 'test@test.com', password: 'pw')),
      expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError on failure',
      build: () {
        when(() => mockLogin(any())).thenAnswer(
            (_) async => const Left(AuthFailure(message: 'Bad creds')));
        return bloc;
      },
      act: (b) =>
          b.add(AuthLoginRequested(email: 'bad@bad.com', password: 'bad')),
      expect: () => [isA<AuthLoading>(), isA<AuthError>()],
    );
  });

  group('AuthLogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits AuthUnauthenticated',
      build: () {
        when(() => mockLogout(any()))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (b) => b.add(AuthLogoutRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthUnauthenticated>()],
    );
  });
}
