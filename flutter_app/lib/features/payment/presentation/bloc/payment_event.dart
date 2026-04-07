import 'package:equatable/equatable.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();
  @override
  List<Object?> get props => [];
}

class PaymentProcessRequested extends PaymentEvent {
  final int bookingId;
  final String method;
  final double totalPrice;
  final String clubName;
  const PaymentProcessRequested({
    required this.bookingId,
    required this.method,
    required this.totalPrice,
    required this.clubName,
  });
  @override
  List<Object?> get props => [bookingId, method];
}
