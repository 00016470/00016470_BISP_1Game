import '../../../../core/network/api_client.dart';
import '../models/wallet_model.dart';

abstract class WalletRemoteDataSource {
  Future<WalletModel> getWallet();
  Future<Map<String, dynamic>> topUp(double amount);
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final ApiClient apiClient;
  WalletRemoteDataSourceImpl(this.apiClient);

  @override
  Future<WalletModel> getWallet() async {
    final response = await apiClient.get('/wallet');
    return WalletModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> topUp(double amount) async {
    final response = await apiClient.post(
      '/wallet/top-up',
      data: {'amount': amount},
    );
    final data = response.data as Map<String, dynamic>;
    return {
      'wallet': WalletModel.fromJson(data['wallet'] as Map<String, dynamic>),
      'reference_code': data['reference_code'],
      'transaction_id': data['transaction_id'],
      'message': data['message'] ?? 'Topped up successfully',
    };
  }
}
