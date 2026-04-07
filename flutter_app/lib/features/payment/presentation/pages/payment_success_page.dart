import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../config/constants.dart';
import '../../domain/entities/payment.dart';

class PaymentSuccessPage extends StatelessWidget {
  final Payment payment;
  final String clubName;

  const PaymentSuccessPage({
    super.key,
    required this.payment,
    required this.clubName,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundPrimary),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF76FF03).withValues(alpha: 0.15),
                  border: Border.all(color: const Color(0xFF76FF03), width: 2),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF76FF03),
                  size: 52,
                ),
              )
                  .animate()
                  .scale(begin: const Offset(0, 0), duration: 400.ms,
                      curve: Curves.elasticOut),
              const SizedBox(height: 32),
              Text(
                payment.method == 'CASH' ? 'BOOKING CREATED' : 'PAYMENT SUCCESSFUL',
                style: GoogleFonts.orbitron(
                  color: const Color(0xFF76FF03),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 8),
              Text(
                payment.method == 'CASH'
                    ? 'Please pay at the club counter'
                    : 'Your session is confirmed!',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 40),
              // Receipt card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(AppConstants.backgroundSecondary),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF76FF03).withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    _ReceiptRow('Club', clubName),
                    _ReceiptRow('Amount',
                        '${fmt.format(payment.amount)} UZS'),
                    _ReceiptRow('Method', payment.method),
                    _ReceiptRow(
                        'Status',
                        payment.method == 'CASH'
                            ? 'PENDING VALIDATION'
                            : 'COMPLETED'),
                    _ReceiptRow(
                        'Time',
                        DateFormat('MMM dd, HH:mm')
                            .format(payment.createdAt.toLocal())),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppConstants.primaryAccent),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'VIEW MY BOOKINGS',
                    style: GoogleFonts.orbitron(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.5),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReceiptRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
          Text(value,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
