
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/constants.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/neon_button.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundPrimary),
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              return _buildProfile(context, state);
            }
            if (state is AuthGuest) {
              return _buildGuestProfile(context);
            }
            return const Center(
              child: CircularProgressIndicator(
                  color: Color(AppConstants.primaryAccent)),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, AuthAuthenticated state) {
    final user = state.user;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildAvatar(user.username),
          const SizedBox(height: 16),
          Text(
            user.username.toUpperCase(),
            style: GoogleFonts.orbitron(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(AppConstants.primaryAccent),
              letterSpacing: 2,
            ),
          ).animate(delay: 100.ms).fadeIn(),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
          ).animate(delay: 150.ms).fadeIn(),
          const SizedBox(height: 24),
          if (user.totalBookings != null) ...[
            _buildStatsCard(user.totalBookings!),
            const SizedBox(height: 16),
          ],
          _buildInfoCard(user.email, user.phone),
          const SizedBox(height: 24),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildGuestProfile(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline,
                    size: 80, color: Colors.white24)
                .animate()
                .fadeIn()
                .scale(begin: const Offset(0.5, 0.5)),
            const SizedBox(height: 16),
            Text(
              'GUEST MODE',
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white54,
                letterSpacing: 2,
              ),
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 8),
            Text(
              'Sign in to access your profile and bookings',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white38),
            ).animate(delay: 300.ms).fadeIn(),
            const SizedBox(height: 32),
            NeonButton(
              label: 'LOGIN',
              onPressed: () => context.go('/login'),
              icon: Icons.login,
              width: 180,
            ).animate(delay: 400.ms).fadeIn(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.person_rounded,
            color: Color(AppConstants.primaryAccent), size: 28),
        const SizedBox(width: 12),
        Text(
          'PROFILE',
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(AppConstants.primaryAccent),
            letterSpacing: 2,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildAvatar(String username) {
    final initial =
        username.isNotEmpty ? username[0].toUpperCase() : '?';
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(AppConstants.primaryAccent).withOpacity(0.1),
        border: Border.all(
            color: const Color(AppConstants.primaryAccent), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(AppConstants.primaryAccent).withOpacity(0.3),
            blurRadius: 24,
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.orbitron(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(AppConstants.primaryAccent),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildStatsCard(int totalBookings) {
    return GlassCard(
      child: Row(
        children: [
          _StatItem(
            value: totalBookings.toString(),
            label: 'TOTAL BOOKINGS',
            color: const Color(AppConstants.primaryAccent),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white12,
          ),
          _StatItem(
            value: totalBookings > 0 ? 'VIP' : 'MEMBER',
            label: 'STATUS',
            color: totalBookings >= 10
                ? const Color(AppConstants.warningColor)
                : const Color(AppConstants.successColor),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildInfoCard(String email, String phone) {
    return GlassCard(
      child: Column(
        children: [
          _InfoRow(
              icon: Icons.email_outlined,
              label: 'EMAIL',
              value: email),
          if (phone.isNotEmpty) ...[
            Divider(color: Colors.white12, height: 24),
            _InfoRow(
                icon: Icons.phone_outlined, label: 'PHONE', value: phone),
          ],
        ],
      ),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildLogoutButton(BuildContext context) {
    return NeonButton(
      label: 'LOGOUT',
      onPressed: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(AppConstants.backgroundSecondary),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(
              'LOGOUT',
              style: GoogleFonts.orbitron(
                color: const Color(AppConstants.errorColor),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you sure you want to logout?',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Cancel',
                    style: GoogleFonts.inter(color: Colors.white38)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                  context.go('/login');
                },
                child: Text(
                  'Logout',
                  style: GoogleFonts.orbitron(
                    color: const Color(AppConstants.errorColor),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      color: const Color(AppConstants.errorColor),
      width: double.infinity,
      icon: Icons.logout,
    ).animate(delay: 400.ms).fadeIn();
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.orbitron(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 18, color: const Color(AppConstants.primaryAccent)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.orbitron(
                  fontSize: 9, color: Colors.white38, letterSpacing: 1),
            ),
            Text(
              value,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }
}
