import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../config/constants.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../injection.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import '../../domain/entities/transaction.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TransactionBloc>()
        ..add(const TransactionsLoadRequested()),
      child: const _TransactionHistoryContent(),
    );
  }
}

class _TransactionHistoryContent extends StatelessWidget {
  const _TransactionHistoryContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundPrimary),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'TRANSACTIONS',
          style: GoogleFonts.orbitron(
            color: const Color(AppConstants.primaryAccent),
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading || state is TransactionInitial) {
            return const LoadingShimmer();
          }
          if (state is TransactionError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<TransactionBloc>()
                        .add(const TransactionsLoadRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is TransactionsLoaded) {
            return Column(
              children: [
                if (state.summary != null) _SummaryCard(summary: state.summary!),
                _FilterChips(activeFilter: state.activeFilter),
                Expanded(
                  child: state.transactions.isEmpty
                      ? _EmptyState()
                      : RefreshIndicator(
                          color: const Color(AppConstants.primaryAccent),
                          onRefresh: () async {
                            context.read<TransactionBloc>().add(
                                  TransactionsLoadRequested(
                                      typeFilter: state.activeFilter),
                                );
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: state.transactions.length,
                            itemBuilder: (context, index) =>
                                _TransactionCard(
                                  txn: state.transactions[index],
                                ).animate().fadeIn(delay: (index * 40).ms),
                          ),
                        ),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final TransactionSummary summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(AppConstants.backgroundSecondary),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(AppConstants.primaryAccent).withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem('Spent', fmt.format(summary.totalSpent), Colors.red),
          _SummaryItem('Loaded', fmt.format(summary.totalTopUps), const Color(0xFF76FF03)),
          _SummaryItem('Refunded', fmt.format(summary.totalRefunds), Colors.orange),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value UZS',
          style: GoogleFonts.orbitron(color: color, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  final String? activeFilter;
  const _FilterChips({this.activeFilter});

  static const _filters = [null, 'TOP_UP', 'BOOKING_PAYMENT', 'REFUND'];
  static const _labels = ['All', 'Top-ups', 'Payments', 'Refunds'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, i) {
          final isActive = _filters[i] == activeFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_labels[i]),
              selected: isActive,
              onSelected: (_) => context.read<TransactionBloc>().add(
                    TransactionsLoadRequested(typeFilter: _filters[i]),
                  ),
              labelStyle: GoogleFonts.inter(
                color: isActive ? Colors.black : Colors.white70,
                fontSize: 12,
              ),
              selectedColor: const Color(AppConstants.primaryAccent),
              backgroundColor: const Color(AppConstants.backgroundSecondary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              side: BorderSide(
                color: isActive
                    ? const Color(AppConstants.primaryAccent)
                    : Colors.white24,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final AppTransaction txn;
  const _TransactionCard({required this.txn});

  IconData _icon() {
    switch (txn.type) {
      case 'TOP_UP':
        return Icons.arrow_downward_rounded;
      case 'BOOKING_PAYMENT':
        return Icons.arrow_upward_rounded;
      case 'REFUND':
        return Icons.undo_rounded;
      default:
        return Icons.swap_horiz_rounded;
    }
  }

  Color _color() {
    if (txn.isCredit) return const Color(0xFF76FF03);
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final date = DateFormat('MMM dd, HH:mm').format(txn.createdAt.toLocal());
    final color = _color();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(AppConstants.backgroundSecondary),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon(), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.description,
                  style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${txn.referenceCode} • $date',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${txn.isCredit ? '+' : '-'}${fmt.format(txn.amount)} UZS',
                style: GoogleFonts.orbitron(
                    color: color, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: txn.status == 'COMPLETED'
                      ? const Color(0xFF76FF03).withValues(alpha: 0.15)
                      : txn.status == 'PENDING'
                          ? Colors.orange.withValues(alpha: 0.15)
                          : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  txn.status,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: txn.status == 'COMPLETED'
                        ? const Color(0xFF76FF03)
                        : txn.status == 'PENDING'
                            ? Colors.orange
                            : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined, color: Colors.white24, size: 64),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: GoogleFonts.orbitron(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
