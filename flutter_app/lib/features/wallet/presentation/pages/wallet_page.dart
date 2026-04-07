import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/constants.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';
import '../../../../injection.dart';
import '../../domain/entities/wallet.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => WalletPageState();
}

class WalletPageState extends State<WalletPage> {
  late final WalletBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<WalletBloc>()..add(const WalletLoadRequested());
  }

  /// Called externally (e.g. from HomeScaffold via GlobalKey) to reload wallet data.
  void refresh() {
    _bloc.add(const WalletLoadRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: const _WalletPageContent(),
    );
  }
}

class _WalletPageContent extends StatelessWidget {
  const _WalletPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundPrimary),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'MY WALLET',
          style: GoogleFonts.orbitron(
            color: const Color(AppConstants.primaryAccent),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          if (state is WalletLoading || state is WalletInitial) {
            return const LoadingShimmer();
          }
          if (state is WalletError) {
            return Center(
              child: Text(state.message,
                  style: const TextStyle(color: Colors.red)),
            );
          }
          final wallet = state is WalletLoaded
              ? state.wallet
              : state is WalletTopUpSuccess
                  ? state.wallet
                  : state is WalletTopUpInProgress
                      ? state.wallet
                      : null;

          if (wallet == null) return const SizedBox();

          return RefreshIndicator(
            color: const Color(AppConstants.primaryAccent),
            onRefresh: () async {
              context.read<WalletBloc>().add(const WalletLoadRequested());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _WalletCard(wallet: wallet).animate().fadeIn().slideY(begin: -0.1),
                  const SizedBox(height: 24),
                  _QuickTopUpSection(wallet: wallet)
                      .animate()
                      .fadeIn(delay: 200.ms),
                  const SizedBox(height: 24),
                  _RecentTransactionsLink()
                      .animate()
                      .fadeIn(delay: 300.ms),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  final Wallet wallet;
  const _WalletCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2137), Color(0xFF001529)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(AppConstants.primaryAccent).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(AppConstants.primaryAccent).withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'GAMING WALLET',
                      style: GoogleFonts.orbitron(
                        color: const Color(AppConstants.primaryAccent),
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                    const Icon(Icons.account_balance_wallet_rounded,
                        color: Color(AppConstants.primaryAccent), size: 20),
                  ],
                ),
                const Spacer(),
                Text(
                  wallet.formattedBalance,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Available Balance',
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickTopUpSection extends StatelessWidget {
  final Wallet wallet;
  const _QuickTopUpSection({required this.wallet});

  static const _amounts = [25000.0, 50000.0, 100000.0, 200000.0];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK TOP-UP',
          style: GoogleFonts.orbitron(
            color: Colors.white70,
            fontSize: 11,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: _amounts
              .map((amount) => _TopUpButton(amount: amount))
              .toList(),
        ),
        const SizedBox(height: 16),
        _CustomAmountButton(),
      ],
    );
  }
}

class _TopUpButton extends StatelessWidget {
  final double amount;
  const _TopUpButton({required this.amount});

  @override
  Widget build(BuildContext context) {
    return BlocListener<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state is WalletTopUpSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '+${state.amount.toStringAsFixed(0)} UZS added! ${state.referenceCode}',
                style: const TextStyle(color: Colors.black),
              ),
              backgroundColor: const Color(0xFF76FF03),
            ),
          );
        } else if (state is WalletError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: GestureDetector(
        onTap: () {
          context.read<WalletBloc>().add(WalletTopUpRequested(amount));
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(AppConstants.backgroundSecondary),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(AppConstants.primaryAccent).withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: Text(
              '+${(amount / 1000).toStringAsFixed(0)}K UZS',
              style: GoogleFonts.orbitron(
                color: const Color(AppConstants.primaryAccent),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomAmountButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => context.push('/wallet/top-up'),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(AppConstants.primaryAccent)),
          foregroundColor: const Color(AppConstants.primaryAccent),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          'CUSTOM AMOUNT',
          style: GoogleFonts.orbitron(fontSize: 12, letterSpacing: 1.5),
        ),
      ),
    );
  }
}

class _RecentTransactionsLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/transactions'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(AppConstants.backgroundSecondary),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white12,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.history_rounded,
                color: Color(AppConstants.primaryAccent)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Transaction History',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
