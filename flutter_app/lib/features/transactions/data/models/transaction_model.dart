import '../../domain/entities/transaction.dart';

class TransactionModel extends AppTransaction {
  const TransactionModel({
    required super.id,
    required super.walletId,
    required super.userId,
    super.bookingId,
    required super.type,
    required super.amount,
    required super.balanceBefore,
    required super.balanceAfter,
    required super.status,
    required super.description,
    required super.referenceCode,
    required super.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as int,
        walletId: json['wallet_id'] as int,
        userId: json['user_id'] as int,
        bookingId: json['booking_id'] as int?,
        type: json['type'] as String,
        amount: (json['amount'] as num).toDouble(),
        balanceBefore: (json['balance_before'] as num).toDouble(),
        balanceAfter: (json['balance_after'] as num).toDouble(),
        status: json['status'] as String,
        description: json['description'] as String,
        referenceCode: json['reference_code'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class TransactionListModel extends TransactionList {
  const TransactionListModel({
    required super.items,
    required super.total,
    required super.page,
    required super.perPage,
    required super.pages,
  });

  factory TransactionListModel.fromJson(Map<String, dynamic> json) =>
      TransactionListModel(
        items: (json['items'] as List)
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        page: json['page'] as int,
        perPage: json['per_page'] as int,
        pages: json['pages'] as int,
      );
}

class TransactionSummaryModel extends TransactionSummary {
  const TransactionSummaryModel({
    required super.totalSpent,
    required super.totalTopUps,
    required super.totalRefunds,
    required super.currentBalance,
    required super.transactionCount,
  });

  factory TransactionSummaryModel.fromJson(Map<String, dynamic> json) =>
      TransactionSummaryModel(
        totalSpent: (json['total_spent'] as num).toDouble(),
        totalTopUps: (json['total_top_ups'] as num).toDouble(),
        totalRefunds: (json['total_refunds'] as num).toDouble(),
        currentBalance: (json['current_balance'] as num).toDouble(),
        transactionCount: json['transaction_count'] as int,
      );
}
