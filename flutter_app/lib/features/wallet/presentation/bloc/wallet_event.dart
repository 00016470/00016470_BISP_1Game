import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();
  @override
  List<Object?> get props => [];
}

class WalletLoadRequested extends WalletEvent {
  const WalletLoadRequested();
}

class WalletTopUpRequested extends WalletEvent {
  final double amount;
  const WalletTopUpRequested(this.amount);
  @override
  List<Object?> get props => [amount];
}
