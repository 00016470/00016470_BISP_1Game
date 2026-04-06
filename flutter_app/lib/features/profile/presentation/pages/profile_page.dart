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
import '../../../bookings/presentation/bloc/bookings_bloc.dart';
import '../../../bookings/presentation/bloc/bookings_event.dart';
import '../../../bookings/presentation/bloc/bookings_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Ensure bookings are loaded for the stats section
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<BookingsBloc>();
      if (bloc.state is BookingsInitial) {
        bloc.add(BookingsLoadRequested());
      }
    });
  }

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
    return RefreshIndicator(
      onRefresh: () async {
        context.read<AuthBloc>().add(AuthCheckRequested());
        context.read<BookingsBloc>().add(BookingsLoadRequested());
      },
      color: const Color(AppConstants.primaryAccent),
      backgroundColor: const Color(AppConstants.backgroundSecondary),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
            if (user.joinedAt != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule_outlined,
                      size: 12, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(
                    'Member since ${user.joinedAt}',
                    style:
                        GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                  ),
                ],
              ).animate(delay: 200.ms).fadeIn(),
            ],
            const SizedBox(height: 24),
            _buildStatsSection(user.totalBookings),
            const SizedBox(height: 16),
            _buildInfoCard(user.email, user.phone),
            const SizedBox(height: 16),
            _buildMemberTierCard(user.totalBookings),
            const SizedBox(height: 16),
            _buildRecentBookingsPreview(),
            const SizedBox(height: 24),
            _buildLogoutButton(context),
            const SizedBox(height: 16),
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
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.refresh,
              color: Color(AppConstants.primaryAccent), size: 20),
          onPressed: () {
            context.read<AuthBloc>().add(AuthCheckRequested());
            context.read<BookingsBloc>().add(BookingsLoadRequested());
          },
          tooltip: 'Refresh',
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildAvatar(String username) {
    final initial =
        username.isNotEmpty ? username[0].toUpperCase() : '?';
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(AppConstants.primaryAccent).withValues(alpha: 0.2),
            const Color(AppConstants.surfaceColor).withValues(alpha: 0.6),
          ],
        ),
        border: Border.all(
            color: const Color(AppConstants.primaryAccent), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(AppConstants.primaryAccent).withValues(alpha: 0.3),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.orbitron(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: const Color(AppConstants.primaryAccent),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildStatsSection(int? totalBookings) {
    return BlocBuilder<BookingsBloc, BookingsState>(
      builder: (context, state) {
        int upcoming = 0;
        int past = 0;
        int total = totalBookings ?? 0;

        if (state is BookingsLoaded) {
          upcoming = state.upcomingBookings.length;
          past = state.pastBookings.length;
          total = state.bookings.length;
        }

        return GlassCard(
          child: Row(
            children: [
              _StatItem(
                value: total.toString(),
                label: 'TOTAL',
                color: const Color(AppConstants.primaryAccent),
              ),
              _divider(),
              _StatItem(
                value: upcoming.toString(),
                label: 'UPCOMING',
                color: const Color(AppConstants.successColor),
              ),
              _divider(),
              _StatItem(
                value: past.toString(),
                label: 'COMPLETED',
                color: Colors.white38,
              ),
            ],
          ),
        ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1);
      },
    );
  }

  Widget _divider() => Container(width: 1, height: 40, color: Colors.white12);

  Widget _buildInfoCard(String email, String? phone) {
    return GlassCard(
      child: Column(
        children: [
          _InfoRow(
              icon: Icons.email_outlined, label: 'EMAIL', value: email),
          if (phone != null && phone.isNotEmpty) ...[
            Divider(color: Colors.white12, height: 24),
            _InfoRow(
                icon: Icons.phone_outlined, label: 'PHONE', value: phone),
          ],
        ],
      ),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildMemberTierCard(int? totalBookings) {
    final count = totalBookings ?? 0;
    final tier = _getMemberTier(count);
    final tierColor = _getTierColor(count);
    final progress = _getTierProgress(count);
    final nextTier = _getNextTierLabel(count);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getTierIcon(count), color: tierColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'MEMBERSHIP TIER',
                style: GoogleFonts.orbitron(
                    fontSize: 10, color: Colors.white38, letterSpacing: 1),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tierColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  tier,
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: tierColor,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(tierColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            nextTier,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
          ),
        ],
      ),
    ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildRecentBookingsPreview() {
    return BlocBuilder<BookingsBloc, BookingsState>(
      builder: (context, state) {
        if (state is! BookingsLoaded || state.bookings.isEmpty) {
          return const SizedBox.shrink();
        }
        final recent = state.bookings.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'RECENT BOOKINGS',
                style: GoogleFonts.orbitron(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white38,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            ...recent.map((b) => _MiniBookingRow(booking: b)),
          ],
        ).animate(delay: 400.ms).fadeIn();
      },
    );
  }

  Widget _buildGuestProfile(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline, size: 80, color: Colors.white24)
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
    ).animate(delay: 450.ms).fadeIn();
  }

  // --- Tier helpers ---
  String _getMemberTier(int count) {
    if (count >= 20) return 'PLATINUM';
    if (count >= 10) return 'GOLD';
    if (count >= 5) return 'SILVER';
    return 'BRONZE';
  }

  Color _getTierColor(int count) {
    if (count >= 20) return const Color(0xFF00E5FF);
    if (count >= 10) return const Color(AppConstants.warningColor);
    if (count >= 5) return Colors.grey.shade400;
    return const Color(0xFFCD7F32);
  }

  IconData _getTierIcon(int count) {
    if (count >= 20) return Icons.diamond_outlined;
    if (count >= 10) return Icons.emoji_events_outlined;
    if (count >= 5) return Icons.workspace_premium_outlined;
    return Icons.military_tech_outlined;
  }

  double _getTierProgress(int count) {
    if (count >= 20) return 1.0;
    if (count >= 10) return (count - 10) / 10.0;
    if (count >= 5) return (count - 5) / 5.0;
    return count / 5.0;
  }

  String _getNextTierLabel(int count) {
    if (count >= 20) return 'Max tier reached — Platinum Elite';
    if (count >= 10) return '${20 - count} more bookings to reach Platinum';
    if (count >= 5) return '${10 - count} more bookings to reach Gold';
    return '${5 - count} more bookings to reach Silver';
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

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
            style: GoogleFonts.inter(fontSize: 9, color: Colors.white38),
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
        Icon(icon, size: 18, color: const Color(AppConstants.primaryAccent)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
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
        ),
      ],
    );
  }
}

class _MiniBookingRow extends StatelessWidget {
  final dynamic booking;
  const _MiniBookingRow({required this.booking});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch ((booking.status as String).toUpperCase()) {
      case 'ACTIVE':
        statusColor = const Color(AppConstants.primaryAccent);
        break;
      case 'COMPLETED':
        statusColor = const Color(AppConstants.successColor);
        break;
      case 'CANCELLED':
        statusColor = const Color(AppConstants.errorColor);
        break;
      default:
        statusColor = const Color(AppConstants.warningColor);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(AppConstants.backgroundSecondary),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.clubName as String,
                  style: GoogleFonts.orbitron(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  booking.date as String,
                  style:
                      GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                ),
              ],
            ),
          ),
          Text(
            '${(booking.totalPrice as double).toStringAsFixed(0)} UZS',
            style: GoogleFonts.orbitron(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(AppConstants.primaryAccent),
            ),
          ),
        ],
      ),
    );
  }
}
