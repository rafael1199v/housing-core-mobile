import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

class DioClient {
  const DioClient._();

  static BaseOptions _baseOptions() => BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    contentType: Headers.jsonContentType,
    validateStatus: (status) => status != null && status < 400,
  );

  static Dio createRefreshClient() => Dio(_baseOptions());

  static Dio create({
    required TokenStorage tokenStorage,
    required Dio refreshClient,
    void Function()? onSessionExpired,
  }) {
    final dio = Dio(_baseOptions());

    dio.interceptors.add(
      AuthInterceptor(
        tokenStorage: tokenStorage,
        refreshClient: refreshClient,
        onSessionExpired: onSessionExpired,
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }

    return dio;
  }
}
