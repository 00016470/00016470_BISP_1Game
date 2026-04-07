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

class AdminPaymentsPage extends StatelessWidget {
  const AdminPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdminBloc>()
        ..add(const AdminPendingPaymentsLoadRequested()),
      child: const _AdminPaymentsContent(),
    );
  }
}

class _AdminPaymentsContent extends StatelessWidget {
  const _AdminPaymentsContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundPrimary),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'PENDING PAYMENTS',
          style: GoogleFonts.orbitron(
            color: const Color(AppConstants.primaryAccent),
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is AdminPaymentValidated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment validated successfully!',
                    style: TextStyle(color: Colors.black)),
                backgroundColor: Color(0xFF76FF03),
              ),
            );
            context
                .read<AdminBloc>()
                .add(const AdminPendingPaymentsLoadRequested());
          } else if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminLoading || state is AdminInitial) {
            return const LoadingShimmer();
          }
          if (state is AdminError) {
            return Center(
                child: Text(state.message,
                    style: const TextStyle(color: Colors.red)));
          }
          if (state is AdminPaymentsLoaded) {
            if (state.payments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        color: Color(0xFF76FF03), size: 64),
                    const SizedBox(height: 16),
                    Text('No pending payments',
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
                  .add(const AdminPendingPaymentsLoadRequested()),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.payments.length,
                itemBuilder: (context, i) => _PaymentCard(
                  payment: state.payments[i],
                ).animate().fadeIn(delay: (i * 60).ms),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final AdminPaymentItem payment;
  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(AppConstants.backgroundSecondary),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payments_rounded,
                  color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  payment.username,
                  style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('PENDING',
                    style: GoogleFonts.inter(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            payment.clubName,
            style:
                GoogleFonts.inter(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            '${fmt.format(payment.amount)} UZS • CASH',
            style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context
                      .read<AdminBloc>()
                      .add(AdminPaymentValidateRequested(payment.id)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF76FF03)),
                    foregroundColor: const Color(0xFF76FF03),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('VALIDATE',
                      style:
                          GoogleFonts.orbitron(fontSize: 11, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
