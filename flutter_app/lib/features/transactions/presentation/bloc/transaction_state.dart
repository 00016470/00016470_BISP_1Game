import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();
  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

class TransactionsLoaded extends TransactionState {
  final List<AppTransaction> transactions;
  final TransactionSummary? summary;
  final String? activeFilter;
  const TransactionsLoaded({
    required this.transactions,
    this.summary,
    this.activeFilter,
  });
  @override
  List<Object?> get props => [transactions, summary, activeFilter];
}

class TransactionError extends TransactionState {
  final String message;
  const TransactionError(this.message);
  @override
  List<Object?> get props => [message];
}
