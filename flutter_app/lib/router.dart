import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/bookings/presentation/bloc/bookings_bloc.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/clubs/presentation/pages/club_detail_page.dart';
import 'features/wallet/presentation/pages/wallet_page.dart';
import 'features/wallet/presentation/pages/top_up_page.dart';
import 'features/transactions/presentation/pages/transaction_history_page.dart';
import 'features/map/presentation/pages/club_locator_page.dart';
import 'home_scaffold.dart';
import 'injection.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => BlocProvider.value(
        value: sl<AuthBloc>(),
        child: const SplashPage(),
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => BlocProvider.value(
        value: sl<AuthBloc>(),
        child: const LoginPage(),
      ),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => BlocProvider.value(
        value: sl<AuthBloc>(),
        child: const RegisterPage(),
      ),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => BlocProvider.value(
        value: sl<AuthBloc>(),
        child: const HomeScaffold(),
      ),
    ),
    GoRoute(
      path: '/clubs/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: sl<AuthBloc>()),
            BlocProvider(create: (_) => sl<BookingsBloc>()),
          ],
          child: ClubDetailPage(clubId: id),
        );
      },
    ),
    GoRoute(
      path: '/wallet',
      builder: (context, state) => const WalletPage(),
    ),
    GoRoute(
      path: '/wallet/top-up',
      builder: (context, state) => const TopUpPage(),
    ),
    GoRoute(
      path: '/transactions',
      builder: (context, state) => const TransactionHistoryPage(),
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ClubLocatorPage(
          focusClubId: extra?['clubId'] as int?,
          focusClubName: extra?['clubName'] as String?,
          focusLatitude: extra?['latitude'] as double?,
          focusLongitude: extra?['longitude'] as double?,
        );
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(
        'Page not found: ${state.error}',
        style: const TextStyle(color: Colors.white),
      ),
    ),
  ),
);
