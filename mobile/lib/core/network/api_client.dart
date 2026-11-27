import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show GoTrueClient, Supabase;

import '../env.dart';

/// Error returned by the API (RFC 9457 problem details) or the network layer.
class ApiException implements Exception {
  ApiException({required this.status, required this.code, required this.message, this.fieldErrors = const {}});

  /// HTTP status, 0 for network errors.
  final int status;

  /// Stable machine code (`not_found`, `validation_error`, `network`, ...). Used for translations.
  final String code;
  final String message;
  final Map<String, List<String>> fieldErrors;

  bool get isNetwork => status == 0;

  factory ApiException.fromDio(DioException e) {
    final response = e.response;
    if (response == null) {
      return ApiException(status: 0, code: 'network', message: 'No connection to the server.');
    }
    final data = response.data;
    if (data is Map) {
      final errors = <String, List<String>>{};
      if (data['errors'] is Map) {
        (data['errors'] as Map).forEach((k, v) => errors['$k'] = (v as List).map((x) => '$x').toList());
      }
      return ApiException(
        status: response.statusCode ?? 500,
        code: '${data['code'] ?? 'http_${response.statusCode}'}',
        message: '${data['detail'] ?? data['title'] ?? 'Request failed.'}',
        fieldErrors: errors,
      );
    }
    return ApiException(status: response.statusCode ?? 500, code: 'http_${response.statusCode}', message: 'Request failed.');
  }

  @override
  String toString() => 'ApiException($status, $code): $message';
}

/// Thin typed wrapper around Dio that adds the Supabase access token and maps errors.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) => _run(() => _dio.get<T>(path, queryParameters: query));
  Future<T> post<T>(String path, {Object? body}) => _run(() => _dio.post<T>(path, data: body));
  Future<T> put<T>(String path, {Object? body}) => _run(() => _dio.put<T>(path, data: body));
  Future<T> patch<T>(String path, {Object? body}) => _run(() => _dio.patch<T>(path, data: body));
  Future<T> delete<T>(String path) => _run(() => _dio.delete<T>(path));

  Future<T> _run<T>(Future<Response<T>> Function() call) async {
    try {
      final response = await call();
      return response.data as T;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

class _AuthInterceptor extends QueuedInterceptor {
  _AuthInterceptor(this._dio);

  final Dio _dio;

  GoTrueClient get _auth => Supabase.instance.client.auth;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _auth.currentSession?.accessToken;
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // One retry after refreshing an expired session.
    final alreadyRetried = err.requestOptions.extra['retried'] == true;
    if (err.response?.statusCode == 401 && !alreadyRetried && _auth.currentSession != null) {
      try {
        final refreshed = await _auth.refreshSession();
        final token = refreshed.session?.accessToken;
        if (token != null) {
          final options = err.requestOptions
            ..headers['Authorization'] = 'Bearer $token'
            ..extra['retried'] = true;
          return handler.resolve(await _dio.fetch(options));
        }
      } catch (_) {
        // Fall through: the original 401 is returned and the app signs out.
      }
    }
    handler.next(err);
  }
}

Dio createDio() {
  final dio = Dio(BaseOptions(
    baseUrl: '${Env.apiBaseUrl.replaceAll(RegExp(r'/$'), '')}/api/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    contentType: Headers.jsonContentType,
    responseType: ResponseType.json,
  ));
  dio.interceptors.add(_AuthInterceptor(dio));
  return dio;
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(createDio()));
