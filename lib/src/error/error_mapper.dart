import 'package:dio/dio.dart';

import 'failure.dart';

class ErrorMapper {
  const ErrorMapper._();

  static Failure map(Object error) {
    if (error is! DioException) {
      return UnknownFailure(error.toString());
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.cancel:
        return const UnknownFailure('request.cancelled');
      case DioExceptionType.badCertificate:
        return const NetworkFailure();
      case DioExceptionType.unknown:
        if (error.response == null) return const NetworkFailure();
        break;
      case DioExceptionType.badResponse:
        break;
    }

    final response = error.response;
    final status = response?.statusCode ?? 0;
    final data = response?.data;

    switch (status) {
      case 400:
        return _map400(data);
      case 401:
        return _map401(data);
      case 429:
        return const RateLimitFailure();
      case >= 500:
        return ServerFailure(traceId: response?.headers.value('X-Trace-Id'));
      default:
        return UnknownFailure('http.$status');
    }
  }

  static Failure _map400(Object? data) {
    if (data is List) {
      final fieldErrors = <String, String>{};
      for (final item in data) {
        if (item is Map) {
          final property = (item['propertyName'] ?? '').toString();
          final message = (item['errorMessage'] ?? '').toString();
          if (property.isNotEmpty && !fieldErrors.containsKey(property)) {
            fieldErrors[property] = message;
          }
        }
      }
      return ValidationFailure(fieldErrors);
    }

    if (data is Map && data['code'] != null) {
      return BusinessFailure(
        data['code'].toString(),
        data['message']?.toString(),
      );
    }

    return const UnknownFailure('bad.request');
  }

  static Failure _map401(Object? data) {
    if (data is Map && data['code'] != null) {
      return UnauthorizedFailure(
        data['code'].toString(),
        data['message']?.toString(),
      );
    }
    return const UnauthorizedFailure();
  }
}
