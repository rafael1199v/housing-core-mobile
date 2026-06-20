import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'auth_meta.dart';

class AuthInterceptor extends QueuedInterceptor {
  final TokenStorage _tokenStorage;
  final Dio _refreshClient;
  final void Function()? onSessionExpired;


  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Dio refreshClient,
    this.onSessionExpired,
  })  : _tokenStorage = tokenStorage,
        _refreshClient = refreshClient;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.requiresAuth) {
      final token = await _tokenStorage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final requestOptions = err.requestOptions;

    final shouldAttemptRefresh = response?.statusCode == 401 &&
        requestOptions.requiresAuth &&
        requestOptions.extra['retried'] != true;

    if (!shouldAttemptRefresh) {
      return handler.next(err);
    }

    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _failSession();
      return handler.next(err);
    }

    try {
      final refreshResponse = await _refreshClient.post<Map<String, dynamic>>(
        '${AppConfig.baseUrl}/api/login/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      final data = refreshResponse.data ?? const {};
      final newAccess = data['accessToken'] as String?;
      final newRefresh = data['refreshToken'] as String?;
      if (newAccess == null || newRefresh == null) {
        await _failSession();
        return handler.next(err);
      }

      await _tokenStorage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );

      requestOptions
        ..headers['Authorization'] = 'Bearer $newAccess'
        ..extra['retried'] = true;

      final retried = await _refreshClient.fetch<dynamic>(requestOptions);
      return handler.resolve(retried);
    } on DioException {
      await _failSession();
      return handler.next(err);
    }
  }

  Future<void> _failSession() async {
    await _tokenStorage.clear();
    onSessionExpired?.call();
  }
}
