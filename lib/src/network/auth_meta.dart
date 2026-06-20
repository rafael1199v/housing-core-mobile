import 'package:dio/dio.dart';

class AuthMeta {
  static const String requiresAuthKey = 'requiresAuth';
}

extension AuthRequestOptions on RequestOptions {
  bool get requiresAuth {
    final value = extra[AuthMeta.requiresAuthKey];
    if (value is bool) return value;
    return true;
  }
}
