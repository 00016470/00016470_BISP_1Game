
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/constants.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/bookings/presentation/bloc/bookings_bloc.dart';
import 'features/clubs/presentation/bloc/clubs_bloc.dart';
import 'features/clubs/presentation/pages/clubs_list_page.dart';
import 'features/bookings/presentation/pages/bookings_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'injection.dart';

class HomeScaffold extends StatefulWidget {
  const HomeScaffold({super.key});

  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> {
  int _currentIndex = 0;

  final _pages = const [
    ClubsListPage(),
    BookingsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ClubsBloc>()),
        BlocProvider(create: (_) => sl<BookingsBloc>()),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // Auth state changes handled globally in router
        },
        child: Scaffold(
          backgroundColor: const Color(AppConstants.backgroundPrimary),
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: _buildNavBar(),
        ),
      ),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(AppConstants.backgroundSecondary),
        border: Border(
          top: BorderSide(
            color: const Color(AppConstants.primaryAccent).withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color(AppConstants.primaryAccent),
        unselectedItemColor: Colors.white24,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.orbitron(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
        unselectedLabelStyle:
            GoogleFonts.orbitron(fontSize: 9, letterSpacing: 1),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.videogame_asset_outlined),
            activeIcon: Icon(Icons.videogame_asset_rounded),
            label: 'CLUBS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_month_rounded),
            label: 'BOOKINGS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person_rounded),
            label: 'PROFILE',
          ),
        ],
      ),
    );
  }
}
