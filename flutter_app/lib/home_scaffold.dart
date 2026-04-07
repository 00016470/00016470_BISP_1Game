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

class HomeScaffold extends StatefulWidget {
  const HomeScaffold({super.key});

  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> {
  // Tracks the _page_ index (not nav index)
  int _pageIndex = 0;

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

  late final _pages = <Widget>[
    const ClubsListPage(),
    const BookingsPage(),
    WalletPage(key: _walletKey),
    const ProfilePage(),
  ];

  static const _adminPage = AdminShell();

  // Nav index 3 = Map (push route), not a tab page
  static const int _mapNavIndex = 3;

  /// Convert page index → nav index (skip the Map slot at nav 3)
  int _pageToNav(int page) => page < 3 ? page : page + 1;

  /// Convert nav index → page index (-1 means push /map)
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
