sealed class Failure {
  final String code;
  final String? message;

  const Failure(this.code, [this.message]);
}

class BusinessFailure extends Failure {
  const BusinessFailure(super.code, [super.message]);
}

class ValidationFailure extends Failure {
  final Map<String, String> fieldErrors;

  const ValidationFailure(this.fieldErrors)
      : super('validation.failed');
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.code = 'unauthorized', super.message]);
}

class RateLimitFailure extends Failure {
  const RateLimitFailure() : super('rate.limited');
}

class ServerFailure extends Failure {
  final String? traceId;
  const ServerFailure({this.traceId}) : super('server.error');
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super('network.error');
}

class UnknownFailure extends Failure {
  const UnknownFailure([String? message]) : super('unknown.error', message);
}
