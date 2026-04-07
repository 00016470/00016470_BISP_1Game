import '../../../../core/network/api_client.dart';
import '../models/transaction_model.dart';

abstract class TransactionRemoteDataSource {
  Future<TransactionListModel> getTransactions({
    String? type,
    String? status,
    int page = 1,
    int perPage = 20,
  });
  Future<TransactionModel> getTransaction(int id);
  Future<TransactionSummaryModel> getSummary();
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final ApiClient apiClient;
  TransactionRemoteDataSourceImpl(this.apiClient);

  @override
  Future<TransactionListModel> getTransactions({
    String? type,
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
    };
    final response = await apiClient.dio.get(
      '/transactions',
      queryParameters: params,
    );
    return TransactionListModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<TransactionModel> getTransaction(int id) async {
    final response = await apiClient.dio.get('/transactions/$id');
    return TransactionModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<TransactionSummaryModel> getSummary() async {
    final response = await apiClient.dio.get('/transactions/summary');
    return TransactionSummaryModel.fromJson(response.data as Map<String, dynamic>);
  }
}
