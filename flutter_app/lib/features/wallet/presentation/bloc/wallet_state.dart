import 'package:equatable/equatable.dart';
import '../../domain/entities/wallet.dart';

abstract class WalletState extends Equatable {
  const WalletState();
  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {
  const WalletInitial();
}

class WalletLoading extends WalletState {
  const WalletLoading();
}

class WalletLoaded extends WalletState {
  final Wallet wallet;
  const WalletLoaded(this.wallet);
  @override
  List<Object?> get props => [wallet];
}

class WalletTopUpInProgress extends WalletState {
  final Wallet wallet;
  const WalletTopUpInProgress(this.wallet);
  @override
  List<Object?> get props => [wallet];
}

class WalletTopUpSuccess extends WalletState {
  final Wallet wallet;
  final String referenceCode;
  final double amount;
  const WalletTopUpSuccess({
    required this.wallet,
    required this.referenceCode,
    required this.amount,
  });
  @override
  List<Object?> get props => [wallet, referenceCode, amount];
}

class WalletError extends WalletState {
  final String message;
  const WalletError(this.message);
  @override
  List<Object?> get props => [message];
}
