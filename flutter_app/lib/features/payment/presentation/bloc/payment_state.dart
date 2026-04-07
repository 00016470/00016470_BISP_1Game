import 'package:equatable/equatable.dart';
import '../../domain/entities/payment.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();
  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

class PaymentProcessing extends PaymentState {
  const PaymentProcessing();
}

class PaymentSuccess extends PaymentState {
  final Payment payment;
  const PaymentSuccess(this.payment);
  @override
  List<Object?> get props => [payment];
}

class PaymentFailure extends PaymentState {
  final String message;
  final bool isInsufficientFunds;
  const PaymentFailure(this.message, {this.isInsufficientFunds = false});
  @override
  List<Object?> get props => [message, isInsufficientFunds];
}
