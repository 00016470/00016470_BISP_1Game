import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/payment.dart';

abstract class PaymentRepository {
  Future<Either<Failure, Payment>> processPayment({
    required int bookingId,
    required String method,
  });
  Future<Either<Failure, Payment>> getPayment(int id);
}
