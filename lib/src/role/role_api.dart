import 'package:dio/dio.dart';

import '../auth/credentials.dart';
import 'app_role.dart';

class RoleApi {
  RoleApi(this._dio);

  final Dio _dio;

  Future<Credentials> assignRole(AppRole role) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/user/roles',
      data: {'Role': role.toWire()},
    );
    return Credentials.fromJson(response.data ?? const {});
  }
}
