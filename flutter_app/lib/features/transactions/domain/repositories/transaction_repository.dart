import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/transaction.dart';

abstract class TransactionRepository {
  Future<Either<Failure, TransactionList>> getTransactions({
    String? type,
    String? status,
    int page,
    int perPage,
  });
  Future<Either<Failure, AppTransaction>> getTransaction(int id);
  Future<Either<Failure, TransactionSummary>> getSummary();
}
