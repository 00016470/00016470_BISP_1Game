import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/constants.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        context.read<AuthBloc>().add(AuthCheckRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated || state is AuthGuest) {
          context.go('/home');
        } else if (state is AuthUnauthenticated) {
          context.go('/login');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(AppConstants.backgroundPrimary),
        body: Stack(
          children: [
            _buildBackground(),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: CustomPaint(painter: _GridPainter()),
    );
  }

  Widget _buildContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(AppConstants.primaryAccent).withOpacity(0.1),
              border: Border.all(
                  color: const Color(AppConstants.primaryAccent), width: 2),
              boxShadow: [
                BoxShadow(
                  color:
                      const Color(AppConstants.primaryAccent).withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.videogame_asset_rounded,
                size: 50, color: Color(AppConstants.primaryAccent)),
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  duration: 600.ms,
                  curve: Curves.elasticOut),
          const SizedBox(height: 32),
          Text(
            'GAMING CLUB',
            style: GoogleFonts.orbitron(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: const Color(AppConstants.primaryAccent),
              letterSpacing: 4,
            ),
          )
              .animate(delay: 400.ms)
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.3, end: 0),
          Text(
            'TASHKENT',
            style: GoogleFonts.orbitron(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white38,
              letterSpacing: 8,
            ),
          )
              .animate(delay: 600.ms)
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.3, end: 0),
          const SizedBox(height: 80),
          SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              backgroundColor:
                  const Color(AppConstants.primaryAccent).withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(
                  Color(AppConstants.primaryAccent)),
              minHeight: 2,
            ),
          ).animate(delay: 1000.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(AppConstants.primaryAccent).withOpacity(0.04)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
