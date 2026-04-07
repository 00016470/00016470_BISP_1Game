import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/wallet_repository.dart';

class TopUpWalletUseCase {
  final WalletRepository repository;
  TopUpWalletUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(double amount) =>
      repository.topUp(amount);
}
