import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../config/constants.dart';
import '../../../../injection.dart';
import '../../../wallet/presentation/bloc/wallet_bloc.dart';
import '../../../wallet/presentation/bloc/wallet_event.dart';
import '../../../wallet/presentation/bloc/wallet_state.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import 'payment_success_page.dart';

class PaymentPage extends StatefulWidget {
  final int bookingId;
  final double totalPrice;
  final String clubName;
  final String date;
  final int computersBooked;
  final double durationHours;

  const PaymentPage({
    super.key,
    required this.bookingId,
    required this.totalPrice,
    required this.clubName,
    required this.date,
    required this.computersBooked,
    required this.durationHours,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with SingleTickerProviderStateMixin {
  String _selectedMethod = 'WALLET';

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<PaymentBloc>()),
        BlocProvider(
            create: (_) =>
                sl<WalletBloc>()..add(const WalletLoadRequested())),
      ],
      child: BlocListener<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => PaymentSuccessPage(
                  payment: state.payment,
                  clubName: widget.clubName,
                ),
              ),
            );
          } else if (state is PaymentFailure && !state.isInsufficientFunds) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: const Color(0xFFFF1744)),
            );
          }
        },
        child: Scaffold(
          backgroundColor: const Color(AppConstants.backgroundPrimary),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'PAYMENT',
              style: GoogleFonts.orbitron(
                color: const Color(AppConstants.primaryAccent),
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OrderSummary(
                  clubName: widget.clubName,
                  date: widget.date,
                  computersBooked: widget.computersBooked,
                  durationHours: widget.durationHours,
                  totalPrice: widget.totalPrice,
                ).animate().fadeIn().slideY(begin: -0.05),
                const SizedBox(height: 24),
                _PaymentMethodSelector(
                  selected: _selectedMethod,
                  onChanged: (v) => setState(() => _selectedMethod = v),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 32),
                _PayButton(
                  bookingId: widget.bookingId,
                  method: _selectedMethod,
                  totalPrice: widget.totalPrice,
                  clubName: widget.clubName,
                ).animate().fadeIn(delay: 200.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final String clubName;
  final String date;
  final int computersBooked;
  final double durationHours;
  final double totalPrice;

  const _OrderSummary({
    required this.clubName,
    required this.date,
    required this.computersBooked,
    required this.durationHours,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(AppConstants.backgroundSecondary),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(AppConstants.primaryAccent).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ORDER SUMMARY',
              style: GoogleFonts.orbitron(
                  color: const Color(AppConstants.primaryAccent),
                  fontSize: 11,
                  letterSpacing: 2)),
          const SizedBox(height: 16),
          _Row('Club', clubName),
          _Row('Date', date),
          _Row('Computers', '$computersBooked PCs'),
          _Row('Duration', '${durationHours.toStringAsFixed(0)}h'),
          const Divider(color: Colors.white12, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL',
                  style: GoogleFonts.orbitron(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.5)),
              Text('${fmt.format(totalPrice)} UZS',
                  style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
          Text(value,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _PaymentMethodSelector(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PAYMENT METHOD',
            style: GoogleFonts.orbitron(
                color: Colors.white70, fontSize: 11, letterSpacing: 2)),
        const SizedBox(height: 12),
        BlocBuilder<WalletBloc, WalletState>(
          builder: (context, walletState) {
            final balance = walletState is WalletLoaded
                ? walletState.wallet.balance
                : null;
            return Column(
              children: [
                _MethodTile(
                  value: 'WALLET',
                  selected: selected,
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Wallet',
                  subtitle: balance != null
                      ? 'Balance: ${NumberFormat('#,###').format(balance)} UZS'
                      : 'Loading...',
                  onTap: () => onChanged('WALLET'),
                  isInsufficient: balance != null,
                ),
                const SizedBox(height: 10),
                _MethodTile(
                  value: 'CARD',
                  selected: selected,
                  icon: Icons.credit_card_rounded,
                  label: 'Card',
                  subtitle: 'Simulated • Always succeeds',
                  onTap: () => onChanged('CARD'),
                ),
                const SizedBox(height: 10),
                _MethodTile(
                  value: 'CASH',
                  selected: selected,
                  icon: Icons.payments_rounded,
                  label: 'Cash',
                  subtitle: 'Pay at club — pending validation',
                  onTap: () => onChanged('CASH'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  final String value;
  final String selected;
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isInsufficient;

  const _MethodTile({
    required this.value,
    required this.selected,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isInsufficient = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(AppConstants.primaryAccent).withValues(alpha: 0.1)
              : const Color(AppConstants.backgroundSecondary),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(AppConstants.primaryAccent)
                : Colors.white24,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected
                    ? const Color(AppConstants.primaryAccent)
                    : Colors.white54,
                size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: Color(AppConstants.primaryAccent), size: 20),
          ],
        ),
      ),
    );
  }
}

class _PayButton extends StatelessWidget {
  final int bookingId;
  final String method;
  final double totalPrice;
  final String clubName;

  const _PayButton({
    required this.bookingId,
    required this.method,
    required this.totalPrice,
    required this.clubName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        final loading = state is PaymentProcessing;
        final isInsufficient =
            state is PaymentFailure && state.isInsufficientFunds;

        return Column(
          children: [
            if (isInsufficient)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.message,
                        style: GoogleFonts.inter(
                            color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ).animate().shakeX(),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: loading
                    ? null
                    : () => context.read<PaymentBloc>().add(
                          PaymentProcessRequested(
                            bookingId: bookingId,
                            method: method,
                            totalPrice: totalPrice,
                            clubName: clubName,
                          ),
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppConstants.primaryAccent),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                        'PAY & CONFIRM',
                        style: GoogleFonts.orbitron(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 2,
                        ),
                      ),
              ),
            ),
            if (isInsufficient) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/wallet'),
                child: Text(
                  'TOP UP WALLET',
                  style: GoogleFonts.orbitron(
                    color: const Color(AppConstants.primaryAccent),
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
