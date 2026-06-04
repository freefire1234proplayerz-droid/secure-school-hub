import 'package:dio/dio.dart';

import 'local_db.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://secure-school-hub-api.onrender.com/api',
      ),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  )..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = LocalDb.token;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));

  Future<Response> post(String path, {Map<String, dynamic>? data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException {
      rethrow;
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? query}) async {
    try {
      return await _dio.get(path, queryParameters: query);
    } on DioException {
      rethrow;
    }
  }

  // Simple offline sync pattern: store pending actions in Hive if offline.
  Future<void> syncPendingActions() async {
    final pending = LocalDb.getCache('pendingActions') as List<dynamic>? ?? [];
    if (pending.isEmpty) return;

    final stillPending = <dynamic>[];

    for (final action in pending) {
      try {
        await _dio.request(
          action['path'] as String,
          data: action['data'],
          options: Options(method: action['method'] as String),
        );
      } catch (_) {
        stillPending.add(action);
      }
    }

    await LocalDb.saveCache('pendingActions', stillPending);
  }

  static Map<String, dynamic> encodePendingAction(
      String method, String path, Map<String, dynamic> data) {
    return {
      'method': method,
      'path': path,
      'data': data,
      'ts': DateTime.now().toIso8601String(),
    };
  }
}
