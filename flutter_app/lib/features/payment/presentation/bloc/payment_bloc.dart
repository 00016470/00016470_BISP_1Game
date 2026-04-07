import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/payment_repository.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository repository;

  PaymentBloc({required this.repository}) : super(const PaymentInitial()) {
    on<PaymentProcessRequested>(_onProcess);
  }

  Future<void> _onProcess(
    PaymentProcessRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentProcessing());
    final result = await repository.processPayment(
      bookingId: event.bookingId,
      method: event.method,
    );
    result.fold(
      (failure) {
        final isInsufficient =
            failure.message.toLowerCase().contains('insufficient');
        emit(PaymentFailure(failure.message, isInsufficientFunds: isInsufficient));
      },
      (payment) => emit(PaymentSuccess(payment)),
    );
  }
}
