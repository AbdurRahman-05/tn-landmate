import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/local_storage.dart';

class ApiClient {
  // Live deployed production backend URL on Render
  static const String productionUrl = 'https://tn-landmate-backend.onrender.com/api/v1';

  // Can be overridden at build time via --dart-define=API_URL=...
  static const String _envApiUrl = String.fromEnvironment('API_URL', defaultValue: productionUrl);
  static String? _overrideUrl;

  static String get baseUrl {
    if (_overrideUrl != null && _overrideUrl!.isNotEmpty) {
      return _overrideUrl!;
    }
    return _envApiUrl;
  }

  late Dio dio;

  ApiClient() {
    _initDio();
    _loadCustomUrl();
  }

  Future<void> _loadCustomUrl() async {
    try {
      final savedUrl = await LocalStorageService.getServerUrl();
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _overrideUrl = savedUrl;
        _initDio();
      }
    } catch (_) {}
  }

  void _initDio() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  Future<void> setBaseUrl(String? newUrl) async {
    _overrideUrl = (newUrl != null && newUrl.trim().isNotEmpty) ? newUrl.trim() : null;
    await LocalStorageService.setServerUrl(_overrideUrl);
    _initDio();
  }

  Future<Response?> safeGet(String path, {Map<String, dynamic>? queryParameters, int maxRetries = 2}) async {
    int attempts = 0;
    while (attempts <= maxRetries) {
      try {
        return await dio.get(path, queryParameters: queryParameters);
      } catch (e) {
        attempts++;
        if (attempts > maxRetries) {
          debugPrint('ApiClient safeGet error on $path: $e');
          return null;
        }
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    return null;
  }

  Future<Response?> safePost(String path, {dynamic data, int maxRetries = 2}) async {
    int attempts = 0;
    while (attempts <= maxRetries) {
      try {
        return await dio.post(path, data: data);
      } catch (e) {
        attempts++;
        if (attempts > maxRetries) {
          debugPrint('ApiClient safePost error on $path: $e');
          return null;
        }
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    return null;
  }

  /// Explicit health check method to test backend connectivity and wake up Render free instance
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final res = await dio.get('/health');
      if (res.statusCode == 200) {
        return {
          'ok': true,
          'statusCode': 200,
          'data': res.data,
          'message': 'Connected successfully (Backend Online)',
        };
      }
      return {
        'ok': false,
        'statusCode': res.statusCode,
        'message': 'Server responded with status ${res.statusCode}',
      };
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return {
          'ok': false,
          'message': 'Connection timed out. Server may be spinning up from idle state (~50s on Render free tier). Please tap Test again.',
        };
      }
      return {
        'ok': false,
        'message': 'Network error: ${e.message ?? e.type.name}',
      };
    } catch (e) {
      return {
        'ok': false,
        'message': 'Error: $e',
      };
    }
  }
}

final apiClient = ApiClient();
