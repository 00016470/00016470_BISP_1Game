import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../config/constants.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../injection.dart';
import '../../domain/entities/admin_stats.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class AdminBookingsPage extends StatelessWidget {
  const AdminBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdminBloc>()..add(const AdminBookingsLoadRequested()),
      child: const _AdminBookingsContent(),
    );
  }
}

class _AdminBookingsContent extends StatelessWidget {
  const _AdminBookingsContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundPrimary),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'ALL BOOKINGS',
          style: GoogleFonts.orbitron(
            color: const Color(AppConstants.primaryAccent),
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading || state is AdminInitial) {
            return const LoadingShimmer();
          }
          if (state is AdminError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(state.message,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => context
                        .read<AdminBloc>()
                        .add(const AdminBookingsLoadRequested()),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(AppConstants.primaryAccent)),
                      foregroundColor: const Color(AppConstants.primaryAccent),
                    ),
                    child: const Text('RETRY'),
                  ),
                ],
              ),
            );
          }
          if (state is AdminBookingsLoaded) {
            if (state.bookings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: Colors.white24, size: 64),
                    const SizedBox(height: 16),
                    Text('No bookings found',
                        style: GoogleFonts.orbitron(
                            color: Colors.white54, fontSize: 14)),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              color: const Color(AppConstants.primaryAccent),
              onRefresh: () async => context
                  .read<AdminBloc>()
                  .add(const AdminBookingsLoadRequested()),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.bookings.length,
                itemBuilder: (context, i) =>
                    _BookingCard(booking: state.bookings[i])
                        .animate()
                        .fadeIn(delay: (i * 50).ms),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final AdminBookingItem booking;
  const _BookingCard({required this.booking});

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return const Color(0xFF76FF03);
      case 'CANCELLED':
        return Colors.red;
      case 'COMPLETED':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  Color _paymentColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'COMPLETED':
        return const Color(0xFF76FF03);
      case 'PENDING':
        return Colors.orange;
      case 'FAILED':
        return Colors.red;
      case 'REFUNDED':
        return Colors.blue;
      default:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final statusColor = _statusColor(booking.status);
    final payColor = _paymentColor(booking.paymentStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(AppConstants.backgroundSecondary),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.videogame_asset_rounded,
                  color: Color(AppConstants.primaryAccent), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  booking.clubName,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  booking.status.toUpperCase(),
                  style: GoogleFonts.inter(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline, color: Colors.white38, size: 14),
              const SizedBox(width: 4),
              Text(booking.username,
                  style: GoogleFonts.inter(
                      color: Colors.white70, fontSize: 13)),
              const Spacer(),
              Text(
                '#${booking.id}',
                style: GoogleFonts.orbitron(
                    color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: Colors.white38, size: 14),
              const SizedBox(width: 4),
              Text(
                '${DateFormat('MMM dd, yyyy').format(booking.startTime)}  '
                '${DateFormat('HH:mm').format(booking.startTime)} – '
                '${DateFormat('HH:mm').format(booking.endTime)}',
                style:
                    GoogleFonts.inter(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${fmt.format(booking.totalPrice.toInt())} UZS',
                style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (booking.paymentMethod != null) ...[
                Text(
                  booking.paymentMethod!.toUpperCase(),
                  style: GoogleFonts.inter(
                      color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(width: 8),
              ],
              if (booking.paymentStatus != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: payColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    booking.paymentStatus!.toUpperCase(),
                    style: GoogleFonts.inter(
                        color: payColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
