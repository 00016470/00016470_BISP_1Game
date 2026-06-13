import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/constants.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/bookings/presentation/bloc/bookings_bloc.dart';
import 'features/bookings/presentation/bloc/bookings_event.dart';
import 'features/clubs/presentation/bloc/clubs_bloc.dart';
import 'features/clubs/presentation/pages/clubs_list_page.dart';
import 'features/bookings/presentation/pages/bookings_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/wallet/presentation/pages/wallet_page.dart';
import 'features/admin/presentation/pages/admin_shell.dart';
import 'injection.dart';

// Page order (IndexedStack): Clubs(0), Bookings(1), Wallet(2), Profile(3), Admin(4)
// Nav  order:                Clubs(0), Bookings(1), Wallet(2), Map(3/push), Profile(4), Admin(5)
// mapNavIndex is always 3. Profile nav = pageIdx + 1 for pageIdx >= 3.

/// The main scaffold widget for the home screen of the application.
/// Manages navigation between different sections: Clubs, Bookings, Wallet, Profile, and Admin (if user is admin).
/// Uses IndexedStack for page management and BottomNavigationBar for navigation.
/// Handles authentication state changes and adjusts available pages accordingly.
class HomeScaffold extends StatefulWidget {
  /// Creates a HomeScaffold widget.
  const HomeScaffold({super.key});

  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

/// The state class for HomeScaffold.
/// Manages the current page index, navigation logic, and Bloc providers.
class _HomeScaffoldState extends State<HomeScaffold> {
  /// Tracks the current page index for the IndexedStack (not nav index).
  int _pageIndex = 0;

  /// Global key for the WalletPage to allow refreshing its state.
  final _walletKey = GlobalKey<WalletPageState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authBloc = context.read<AuthBloc>();
      if (authBloc.state is AuthInitial) {
        authBloc.add(AuthCheckRequested());
      }
    });
  }

  /// List of page widgets for the IndexedStack.
  /// Order: Clubs(0), Bookings(1), Wallet(2), Profile(3)
  late final _pages = <Widget>[
    const ClubsListPage(),
    const BookingsPage(),
    WalletPage(key: _walletKey),
    const ProfilePage(),
  ];

  /// The admin page widget, shown only for admin users.
  static const _adminPage = AdminShell();

  /// Navigation index for the Map item (always 3, but it's a push route).
  static const int _mapNavIndex = 3;

  /// Converts page index to navigation index, skipping the Map slot.
  /// [page] The page index (0-4).
  /// Returns the corresponding navigation index.
  int _pageToNav(int page) => page < 3 ? page : page + 1;

  /// Converts navigation index to page index.
  /// Returns -1 for Map (push route), otherwise the page index.
  int _navToPage(int nav) {
    if (nav == _mapNavIndex) return -1; // push
    return nav < _mapNavIndex ? nav : nav - 1;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ClubsBloc>()),
        BlocProvider(create: (_) => sl<BookingsBloc>()),
      ],
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated && _pageIndex >= 4) {
            setState(() => _pageIndex = 0);
          }
        },
        builder: (context, authState) {
          final isAdmin =
              authState is AuthAuthenticated && authState.user.isAdmin;
          final pages = isAdmin
              ? [..._pages, _adminPage]
              : _pages;

          final safePageIndex =
              _pageIndex < pages.length ? _pageIndex : 0;
          final navIndex = _pageToNav(safePageIndex);

          return Scaffold(
            backgroundColor: const Color(AppConstants.backgroundPrimary),
            body: IndexedStack(
              index: safePageIndex,
              children: pages,
            ),
            bottomNavigationBar: _buildNavBar(
                context, isAdmin, navIndex),
          );
        },
      ),
    );
  }

  /// Builds the bottom navigation bar with appropriate items based on user role.
  /// [context] The build context.
  /// [isAdmin] Whether the current user is an admin.
  /// [currentNavIndex] The current navigation index.
  /// Returns the BottomNavigationBar widget.
  Widget _buildNavBar(
      BuildContext context, bool isAdmin, int currentNavIndex) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(AppConstants.backgroundSecondary),
        border: Border(
          top: BorderSide(
            color: const Color(AppConstants.primaryAccent)
                .withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentNavIndex,
        onTap: (navIdx) {
          final pageIdx = _navToPage(navIdx);
          if (pageIdx == -1) {
            context.push('/map');
          } else {
            if (pageIdx == 1) {
              context.read<BookingsBloc>().add(BookingsLoadRequested());
            }
            if (pageIdx == 2) {
              _walletKey.currentState?.refresh();
            }
            setState(() => _pageIndex = pageIdx);
          }
        },
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color(AppConstants.primaryAccent),
        unselectedItemColor: Colors.white24,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.orbitron(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
        unselectedLabelStyle:
            GoogleFonts.orbitron(fontSize: 8, letterSpacing: 0.8),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.videogame_asset_outlined),
            activeIcon: Icon(Icons.videogame_asset_rounded),
            label: 'CLUBS',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_month_rounded),
            label: 'BOOKINGS',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'WALLET',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map_rounded),
            label: 'MAP',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person_rounded),
            label: 'PROFILE',
          ),
          if (isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              activeIcon: Icon(Icons.admin_panel_settings_rounded),
              label: 'ADMIN',
            ),
        ],
      ),
    );
  }
}
