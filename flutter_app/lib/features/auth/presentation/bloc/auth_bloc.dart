import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/usecases/usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final AuthRepository authRepository;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.authRepository,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthGuestModeEntered>(_onGuestModeEntered);
  }

  Future<void> _onCheckRequested(
      AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final isLoggedIn = await authRepository.isLoggedIn();
    if (isLoggedIn) {
      final result = await authRepository.getCurrentUser();
      result.fold(
        (_) => emit(AuthUnauthenticated()),
        (user) => emit(AuthAuthenticated(user)),
      );
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await loginUseCase(
        LoginParams(email: event.email, password: event.password));
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (data) {
        final userData = data['user'] as Map<String, dynamic>;
        if (data['role'] != null) {
          userData['role'] = data['role'];
        }
        emit(AuthAuthenticated(_userFromMap(userData)));
      },
    );
  }

  Future<void> _onRegisterRequested(
      AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await registerUseCase(RegisterParams(
      username: event.username,
      email: event.email,
      password: event.password,
      phone: event.phone,
    ));
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (data) {
        final userData = data['user'] as Map<String, dynamic>;
        if (data['role'] != null) {
          userData['role'] = data['role'];
        }
        emit(AuthAuthenticated(_userFromMap(userData)));
      },
    );
  }

  Future<void> _onLogoutRequested(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await logoutUseCase(NoParams());
    emit(AuthUnauthenticated());
  }

  void _onGuestModeEntered(
      AuthGuestModeEntered event, Emitter<AuthState> emit) {
    emit(AuthGuest());
  }

  User _userFromMap(Map<String, dynamic> m) {
    return _InlineUser(
      id: m['id'] as int? ?? 0,
      username: m['username'] as String? ?? '',
      email: m['email'] as String? ?? '',
      phone: m['phone'] as String? ?? '',
      totalBookings: m['total_bookings'] as int?,
      joinedAt: m['joined_at'] as String?,
      role: m['role'] as String? ?? 'user',
    );
  }
}

class _InlineUser extends User {
  const _InlineUser({
    required super.id,
    required super.username,
    required super.email,
    required super.phone,
    super.totalBookings,
    super.joinedAt,
    super.role,
  });
}
