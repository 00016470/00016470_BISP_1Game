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

/// The main router configuration for the Flutter application.
/// Uses GoRouter to define navigation routes and their corresponding pages.
/// Includes routes for authentication, home, club details, wallet, transactions, and map.
/// Provides Bloc providers for state management on relevant routes.
final router = GoRouter(
  /// The initial route path when the app starts.
  initialLocation: '/',
  /// List of all defined routes in the application.
  routes: [
    /// Splash page route - the first screen shown on app launch.
    GoRoute(
      path: '/',
      builder: (context, state) => BlocProvider.value(
        value: sl<AuthBloc>(),
        child: const SplashPage(),
      ),
    ),
    /// Login page route for user authentication.
    GoRoute(
      path: '/login',
      builder: (context, state) => BlocProvider.value(
        value: sl<AuthBloc>(),
        child: const LoginPage(),
      ),
    ),
    /// Register page route for new user registration.
    GoRoute(
      path: '/register',
      builder: (context, state) => BlocProvider.value(
        value: sl<AuthBloc>(),
        child: const RegisterPage(),
      ),
    ),
    /// Home page route - main application interface.
    GoRoute(
      path: '/home',
      builder: (context, state) => BlocProvider.value(
        value: sl<AuthBloc>(),
        child: const HomeScaffold(),
      ),
    ),
    /// Club detail page route with dynamic club ID parameter.
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
    /// Wallet page route for viewing wallet balance and transactions.
    GoRoute(
      path: '/wallet',
      builder: (context, state) => const WalletPage(),
    ),
    /// Top-up page route for adding funds to wallet.
    GoRoute(
      path: '/wallet/top-up',
      builder: (context, state) => const TopUpPage(),
    ),
    /// Transaction history page route.
    GoRoute(
      path: '/transactions',
      builder: (context, state) => const TransactionHistoryPage(),
    ),
    /// Club locator map page route with optional focus parameters.
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
  /// Error page builder for handling navigation errors.
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(
        'Page not found: ${state.error}',
        style: const TextStyle(color: Colors.white),
      ),
    ),
  ),
);
