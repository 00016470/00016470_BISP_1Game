import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/usecases/get_wallet_usecase.dart';
import '../../domain/usecases/top_up_wallet_usecase.dart';
import '../../../../core/usecases/usecase.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final GetWalletUseCase getWalletUseCase;
  final TopUpWalletUseCase topUpWalletUseCase;

  Wallet? _cachedWallet;

  WalletBloc({
    required this.getWalletUseCase,
    required this.topUpWalletUseCase,
  }) : super(const WalletInitial()) {
    on<WalletLoadRequested>(_onLoad);
    on<WalletTopUpRequested>(_onTopUp);
  }

  Future<void> _onLoad(
    WalletLoadRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());
    final result = await getWalletUseCase(NoParams());
    result.fold(
      (failure) => emit(WalletError(failure.message)),
      (wallet) {
        _cachedWallet = wallet;
        emit(WalletLoaded(wallet));
      },
    );
  }

  Future<void> _onTopUp(
    WalletTopUpRequested event,
    Emitter<WalletState> emit,
  ) async {
    if (_cachedWallet != null) {
      emit(WalletTopUpInProgress(_cachedWallet!));
    }
    final result = await topUpWalletUseCase(event.amount);
    result.fold(
      (failure) => emit(WalletError(failure.message)),
      (data) {
        final wallet = data['wallet'] as Wallet;
        _cachedWallet = wallet;
        emit(WalletTopUpSuccess(
          wallet: wallet,
          referenceCode: data['reference_code'] as String,
          amount: event.amount,
        ));
      },
    );
  }
}
