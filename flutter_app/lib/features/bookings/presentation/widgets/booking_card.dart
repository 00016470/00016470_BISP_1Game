import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/constants.dart';
import '../../domain/entities/booking.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final int index;

  const BookingCard({super.key, required this.booking, this.index = 0});

  Color get _statusColor {
    switch (booking.status.toUpperCase()) {
      case 'ACTIVE':
        return const Color(AppConstants.primaryAccent);
      case 'COMPLETED':
        return const Color(AppConstants.successColor);
      case 'CANCELLED':
        return const Color(AppConstants.errorColor);
      case 'EXPIRED':
        return const Color(AppConstants.warningColor);
      default:
        return Colors.white38;
    }
  }

  String get _statusLabel {
    switch (booking.status.toUpperCase()) {
      case 'ACTIVE':
        return 'CONFIRMED';
      case 'COMPLETED':
        return 'COMPLETED';
      case 'CANCELLED':
        return 'CANCELLED';
      case 'EXPIRED':
        return 'EXPIRED';
      default:
        return booking.status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(AppConstants.cardColor),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withValues(alpha: 0.05),
            blurRadius: 16,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            if (booking.clubLocation.isNotEmpty) _buildLocation(),
            const SizedBox(height: 10),
            _buildDetails(),
            const SizedBox(height: 12),
            _buildFooter(),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 350.ms)
        .slideX(begin: -0.05, end: 0);
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            booking.clubName,
            style: GoogleFonts.orbitron(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _statusColor.withValues(alpha: 0.4)),
          ),
          child: Text(
            _statusLabel,
            style: GoogleFonts.orbitron(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: _statusColor,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocation() {
    return Row(
      children: [
        Icon(Icons.location_on_outlined,
            size: 13, color: const Color(AppConstants.primaryAccent).withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            booking.clubLocation,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    final durationLabel = booking.durationHours == booking.durationHours.roundToDouble()
        ? '${booking.durationHours.toInt()}h'
        : '${booking.durationHours}h';
    return Column(
      children: [
        _DetailRow(
          icon: Icons.calendar_today_outlined,
          text: booking.date,
          iconColor: const Color(AppConstants.primaryAccent),
        ),
        const SizedBox(height: 6),
        _DetailRow(
          icon: Icons.access_time_outlined,
          text: '${_fmt(booking.startTime)} — ${_fmt(booking.endTime)}',
          iconColor: const Color(AppConstants.primaryAccent),
        ),
        const SizedBox(height: 6),
        _DetailRow(
          icon: Icons.computer_outlined,
          text: '${booking.computersCount} PC · $durationLabel',
          iconColor: const Color(AppConstants.successColor),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Booking #${booking.id}',
          style: GoogleFonts.inter(fontSize: 11, color: Colors.white24),
        ),
        Text(
          '${booking.totalPrice.toStringAsFixed(0)} UZS',
          style: GoogleFonts.orbitron(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(AppConstants.primaryAccent),
          ),
        ),
      ],
    );
  }

  String _fmt(String t) => t.length >= 5 ? t.substring(0, 5) : t;
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;

  const _DetailRow(
      {required this.icon, required this.text, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
        ),
      ],
    );
  }
}
