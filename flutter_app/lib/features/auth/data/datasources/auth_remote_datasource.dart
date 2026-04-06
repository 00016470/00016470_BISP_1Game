import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../config/constants.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(
      {required String email, required String password});
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String phone,
  });
  Future<String> refreshToken(String token);
  Future<void> logout();
  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;
  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<Map<String, dynamic>> login(
      {required String email, required String password}) async {
    final response = await apiClient.post(
      AppConstants.loginEndpoint,
      data: {'email': email, 'password': password},
      requiresAuth: false,
    );
    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    }
    throw ServerException(
        message: 'Login failed', statusCode: response.statusCode);
  }

  @override
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String phone,
  }) async {
    final response = await apiClient.post(
      AppConstants.registerEndpoint,
      data: {
        'username': username,
        'email': email,
        'password': password,
        'phone': phone,
      },
      requiresAuth: false,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.data as Map<String, dynamic>;
    }
    throw ServerException(
        message: 'Registration failed', statusCode: response.statusCode);
  }

  @override
  Future<String> refreshToken(String token) async {
    final response = await apiClient.post(
      AppConstants.refreshEndpoint,
      data: {'refresh': token},
      requiresAuth: false,
    );
    if (response.statusCode == 200) {
      return response.data['access'] as String;
    }
    throw ServerException(
        message: 'Token refresh failed', statusCode: response.statusCode);
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.post(AppConstants.logoutEndpoint);
    } catch (_) {
      // Best-effort logout
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await apiClient.get(AppConstants.meEndpoint);
    if (response.statusCode == 200) {
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    }
    throw ServerException(
        message: 'Failed to get user', statusCode: response.statusCode);
  }
}
