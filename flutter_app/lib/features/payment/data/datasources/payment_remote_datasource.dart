import '../../../../core/network/api_client.dart';
import '../models/payment_model.dart';

abstract class PaymentRemoteDataSource {
  Future<PaymentModel> processPayment({
    required int bookingId,
    required String method,
  });
  Future<PaymentModel> getPayment(int id);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final ApiClient apiClient;
  PaymentRemoteDataSourceImpl(this.apiClient);

  @override
  Future<PaymentModel> processPayment({
    required int bookingId,
    required String method,
  }) async {
    final response = await apiClient.dio.post(
      '/payments/process',
      data: {'booking_id': bookingId, 'method': method},
    );
    return PaymentModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PaymentModel> getPayment(int id) async {
    final response = await apiClient.dio.get('/payments/$id');
    return PaymentModel.fromJson(response.data as Map<String, dynamic>);
  }
}
