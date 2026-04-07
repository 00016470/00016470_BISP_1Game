import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/transaction_repository.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository repository;

  TransactionBloc({required this.repository}) : super(const TransactionInitial()) {
    on<TransactionsLoadRequested>(_onLoad);
    on<TransactionSummaryRequested>(_onSummary);
  }

  Future<void> _onLoad(
    TransactionsLoadRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());

    final txnResult = await repository.getTransactions(
      type: event.typeFilter,
      page: 1,
      perPage: 50,
    );
    final summaryResult = await repository.getSummary();

    txnResult.fold(
      (failure) => emit(TransactionError(failure.message)),
      (list) {
        final summary =
            summaryResult.fold((f) => null, (s) => s);
        emit(TransactionsLoaded(
          transactions: list.items,
          summary: summary,
          activeFilter: event.typeFilter,
        ));
      },
    );
  }

  Future<void> _onSummary(
    TransactionSummaryRequested event,
    Emitter<TransactionState> emit,
  ) async {
    final result = await repository.getSummary();
    result.fold(
      (failure) => emit(TransactionError(failure.message)),
      (summary) {
        final current = state;
        if (current is TransactionsLoaded) {
          emit(TransactionsLoaded(
            transactions: current.transactions,
            summary: summary,
            activeFilter: current.activeFilter,
          ));
        }
      },
    );
  }
}
