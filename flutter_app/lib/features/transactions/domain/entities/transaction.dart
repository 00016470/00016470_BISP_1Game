import 'package:equatable/equatable.dart';

class AppTransaction extends Equatable {
  final int id;
  final int walletId;
  final int userId;
  final int? bookingId;
  final String type;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String status;
  final String description;
  final String referenceCode;
  final DateTime createdAt;

  const AppTransaction({
    required this.id,
    required this.walletId,
    required this.userId,
    this.bookingId,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.status,
    required this.description,
    required this.referenceCode,
    required this.createdAt,
  });

  bool get isCredit => type == 'TOP_UP' || type == 'REFUND';
  bool get isDebit => type == 'BOOKING_PAYMENT';

  @override
  List<Object?> get props => [id, type, amount, status, referenceCode];
}

class TransactionSummary extends Equatable {
  final double totalSpent;
  final double totalTopUps;
  final double totalRefunds;
  final double currentBalance;
  final int transactionCount;

  const TransactionSummary({
    required this.totalSpent,
    required this.totalTopUps,
    required this.totalRefunds,
    required this.currentBalance,
    required this.transactionCount,
  });

  @override
  List<Object?> get props =>
      [totalSpent, totalTopUps, totalRefunds, currentBalance, transactionCount];
}

class TransactionList extends Equatable {
  final List<AppTransaction> items;
  final int total;
  final int page;
  final int perPage;
  final int pages;

  const TransactionList({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    required this.pages,
  });

  @override
  List<Object?> get props => [items, total, page];
}
