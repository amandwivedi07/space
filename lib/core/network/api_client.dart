import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/logger_service.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Dio wrapper: attaches the bearer token, and on a 401 transparently rotates
/// the refresh token (single-flight) and retries the request ONCE.
/// All failures surface as [ApiException].
class ApiClient {
  ApiClient(this._tokens) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final access = _tokens.accessToken;
        if (access != null && options.headers['Authorization'] == null) {
          options.headers['Authorization'] = 'Bearer $access';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final options = error.requestOptions;
        final isAuthPath = options.path.startsWith('/auth/refresh') ||
            options.path.startsWith('/auth/login') ||
            options.path.startsWith('/auth/register');
        // _retried guards against an infinite refresh→401→refresh loop when a
        // request keeps 401-ing even with a fresh token.
        final alreadyRetried = options.extra[_retriedKey] == true;
        if (error.response?.statusCode == 401 &&
            !isAuthPath &&
            !alreadyRetried &&
            _tokens.hasSession) {
          final retried = await _refreshAndRetry(options);
          if (retried != null) return handler.resolve(retried);
        }
        handler.next(error);
      },
    ));
  }

  static const _retriedKey = 'space_retried_after_refresh';

  final TokenStorage _tokens;
  late final Dio _dio;
  Future<bool>? _refreshing; // single-flight refresh

  /// Fired when the refresh token itself is rejected — the session is dead and
  /// the app must return to sign-in. Assigned by the auth layer.
  void Function()? onSessionExpired;

  Future<Response<dynamic>?> _refreshAndRetry(RequestOptions original) async {
    final ok = await (_refreshing ??= _doRefresh().whenComplete(() {
      _refreshing = null;
    }));
    if (!ok) return null;
    // FormData is single-use: a finalized upload body cannot be replayed, so
    // let the caller re-issue those (ApiClient.upload retries explicitly).
    if (original.data is FormData) return null;
    original.headers['Authorization'] = 'Bearer ${_tokens.accessToken}';
    original.extra[_retriedKey] = true;
    try {
      return await _dio.fetch(original);
    } on DioException {
      return null;
    }
  }

  Future<bool> _doRefresh() async {
    final refresh = _tokens.refreshToken;
    if (refresh == null) return false;
    try {
      final res = await _dio.post('/auth/refresh',
          data: {'refresh_token': refresh},
          options: Options(headers: {'Authorization': null}));
      final data = res.data['data'] as Map<String, dynamic>;
      await _tokens.save(
        access: data['access_token'] as String,
        refresh: data['refresh_token'] as String,
      );
      return true;
    } on DioException catch (e) {
      // Only a rejected token kills the session. A network blip must NOT sign
      // the user out — they stay logged in and retry when connectivity returns.
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        Log.w('refresh rejected — session expired');
        await _tokens.clear();
        onSessionExpired?.call();
      } else {
        Log.w('refresh failed (transient): $e');
      }
      return false;
    }
  }

  /// Uploads a local file to POST /media, returning its public URL.
  /// Retries once with a rebuilt body if the access token had expired.
  Future<String> upload(String filePath) async {
    Future<Response<dynamic>> send() async => _dio.post(
          '/media',
          data: FormData.fromMap({'file': await MultipartFile.fromFile(filePath)}),
        );
    try {
      final res = await send();
      return _urlOf(res);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && _tokens.hasSession) {
        final refreshed = await (_refreshing ??= _doRefresh().whenComplete(() {
          _refreshing = null;
        }));
        if (refreshed) {
          try {
            return _urlOf(await send()); // fresh FormData, fresh token
          } on DioException catch (retryError) {
            throw _toApiException(retryError);
          }
        }
      }
      throw _toApiException(e);
    }
  }

  String _urlOf(Response<dynamic> res) {
    final envelope = res.data as Map<String, dynamic>;
    return (envelope['data'] as Map<String, dynamic>)['url'] as String;
  }

  /// Unwraps the backend envelope, returning `data`.
  Future<dynamic> request(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.request(
        path,
        data: body,
        queryParameters: query,
        options: Options(method: method),
      );
      final envelope = res.data;
      if (envelope is Map<String, dynamic>) return envelope['data'];
      return null; // empty/204 responses carry no payload
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    if (e.response == null) return ApiException.network();
    return ApiException.fromBody(
      e.response!.statusCode ?? 0,
      e.response!.data is Map<String, dynamic>
          ? e.response!.data as Map<String, dynamic>
          : null,
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      request('GET', path, query: query);
  Future<dynamic> post(String path, {Object? body}) =>
      request('POST', path, body: body);
  Future<dynamic> patch(String path, {Object? body}) =>
      request('PATCH', path, body: body);
  Future<dynamic> delete(String path) => request('DELETE', path);
}

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(tokenStorageProvider)),
);
