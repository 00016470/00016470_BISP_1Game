import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../error/exceptions.dart';
import '../../config/constants.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  /// Completer used to serialize concurrent token refresh attempts.
  /// While a refresh is in-flight, subsequent 401 handlers wait on this
  /// future instead of issuing redundant refresh requests.
  Completer<String?>? _refreshCompleter;

  ApiClient(this._secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${AppConstants.baseUrl}${AppConstants.apiPrefix}',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token =
              await _secureStorage.read(key: AppConstants.accessTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode != 401) {
            handler.next(error);
            return;
          }

          // If a refresh is already in-flight, wait for its result.
          if (_refreshCompleter != null) {
            final newToken = await _refreshCompleter!.future;
            if (newToken == null) {
              handler.next(error);
            } else {
              handler.resolve(await _retryRequest(error, newToken));
            }
            return;
          }

          // Become the owner of this refresh cycle.
          _refreshCompleter = Completer<String?>();
          try {
            final refreshToken =
                await _secureStorage.read(key: AppConstants.refreshTokenKey);
            if (refreshToken == null) {
              _refreshCompleter!.complete(null);
              _refreshCompleter = null;
              await _secureStorage.deleteAll();
              handler.next(error);
              return;
            }
            final refreshResponse = await _dio.post(
              AppConstants.refreshEndpoint,
              data: {'refresh': refreshToken},
              options: Options(headers: {'Authorization': null}),
            );
            final newAccessToken =
                refreshResponse.data['access'] as String;
            await _secureStorage.write(
                key: AppConstants.accessTokenKey, value: newAccessToken);
            _refreshCompleter!.complete(newAccessToken);
            _refreshCompleter = null;
            handler.resolve(await _retryRequest(error, newAccessToken));
          } catch (_) {
            _refreshCompleter!.complete(null);
            _refreshCompleter = null;
            await _secureStorage.deleteAll();
            handler.next(error);
          }
        },
      ),
    );
  }

  Future<Response> _retryRequest(DioException error, String token) {
    return _dio.request(
      error.requestOptions.path,
      data: error.requestOptions.data,
      queryParameters: error.requestOptions.queryParameters,
      options: Options(
        method: error.requestOptions.method,
        headers: {
          ...error.requestOptions.headers,
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on SocketException {
      throw const NetworkException();
    }
  }

  Future<Response> post(String path,
      {dynamic data, bool requiresAuth = true}) async {
    try {
      Options? options;
      if (!requiresAuth) {
        options = Options(headers: {'Authorization': null});
      }
      return await _dio.post(path, data: data, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on SocketException {
      throw const NetworkException();
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      return const NetworkException();
    }
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    String message = 'An error occurred';
    if (data is Map) {
      if (data.containsKey('detail')) {
        message = data['detail'].toString();
      } else if (data.containsKey('non_field_errors')) {
        message = (data['non_field_errors'] as List).first.toString();
      } else if (data.containsKey('message')) {
        message = data['message'].toString();
      } else if (data.isNotEmpty) {
        final firstKey = data.keys.first;
        final firstVal = data[firstKey];
        if (firstVal is List && firstVal.isNotEmpty) {
          message = firstVal.first.toString();
        } else {
          message = firstVal.toString();
        }
      }
    }
    if (statusCode == 401) throw AuthException(message: message);
    if (statusCode == 409) throw ConflictException(message: message);
    return ServerException(message: message, statusCode: statusCode);
  }

  Dio get dio => _dio;
}
