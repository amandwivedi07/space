/// A normalized API failure carrying the backend's error envelope:
/// {"success":false,"message":..., "error":KIND, "errors":{field:msg}}.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.code = 'UNKNOWN',
    this.statusCode = 0,
    this.fieldErrors = const {},
  });

  final String message;
  final String code; // backend error kind, e.g. UNAUTHORIZED, VALIDATION_ERROR
  final int statusCode;
  final Map<String, String> fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isNetwork => statusCode == 0;

  factory ApiException.fromBody(int status, Map<String, dynamic>? body) {
    if (body == null) {
      return ApiException(
          message: 'Something went wrong', statusCode: status);
    }
    final errors = <String, String>{};
    (body['errors'] as Map<String, dynamic>?)
        ?.forEach((k, v) => errors[k] = v.toString());
    return ApiException(
      message: body['message'] as String? ?? 'Something went wrong',
      code: body['error'] as String? ?? 'UNKNOWN',
      statusCode: status,
      fieldErrors: errors,
    );
  }

  factory ApiException.network() => const ApiException(
        message: "Can't reach Space right now — check your connection",
        code: 'NETWORK',
      );

  @override
  String toString() => 'ApiException($statusCode $code: $message)';
}
