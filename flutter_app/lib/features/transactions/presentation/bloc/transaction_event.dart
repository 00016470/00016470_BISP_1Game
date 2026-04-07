import 'package:equatable/equatable.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();
  @override
  List<Object?> get props => [];
}

class TransactionsLoadRequested extends TransactionEvent {
  final String? typeFilter;
  final bool refresh;
  const TransactionsLoadRequested({this.typeFilter, this.refresh = false});
  @override
  List<Object?> get props => [typeFilter, refresh];
}

class TransactionSummaryRequested extends TransactionEvent {
  const TransactionSummaryRequested();
}
