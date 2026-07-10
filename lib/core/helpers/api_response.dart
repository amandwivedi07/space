import '../utils/result.dart';

/// Envelope the future REST/WebSocket API is expected to return.
/// Repositories map this to [Result] so viewmodels stay transport-agnostic.
class ApiResponse<T> {
  const ApiResponse({this.data, this.error, this.statusCode = 200});

  final T? data;
  final String? error;
  final int statusCode;

  bool get isOk => statusCode >= 200 && statusCode < 300 && error == null;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? data) parse,
  ) =>
      ApiResponse(
        data: json['data'] == null ? null : parse(json['data']),
        error: json['error'] as String?,
        statusCode: (json['status'] as num?)?.toInt() ?? 200,
      );

  Result<T> toResult({String fallbackError = 'Something went wrong'}) {
    if (isOk && data != null) return Success(data as T);
    return Failure(error ?? fallbackError);
  }
}
