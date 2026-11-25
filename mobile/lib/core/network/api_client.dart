import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/local_storage.dart';

class ApiClient {
  // Live deployed production backend URL on Render
  static const String productionUrl = 'https://tn-landmate-backend.onrender.com/api/v1';

  // Standard Local Development Endpoints
  static const String localhostUrl = 'http://127.0.0.1:8000/api/v1';
  static const String androidEmulatorUrl = 'http://10.0.2.2:8000/api/v1';
  static const String lanWifiUrl = 'http://10.112.85.2:8000/api/v1';

  // Can be overridden at build time via --dart-define=API_URL=...
  static const String _envApiUrl = String.fromEnvironment('API_URL', defaultValue: '');
  static String? _overrideUrl;

  /// Determines the smartest default URL based on runtime platform and environment
  static String get defaultUrl {
    if (_envApiUrl.isNotEmpty) return _envApiUrl;
    if (kDebugMode) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        return androidEmulatorUrl;
      }
      return localhostUrl;
    }
    return productionUrl;
  }

  static String get baseUrl {
    if (_overrideUrl != null && _overrideUrl!.isNotEmpty) {
      return _overrideUrl!;
    }
    return defaultUrl;
  }

  late Dio dio;
  Future<void>? _initFuture;

  ApiClient() {
    _initDio();
    _initFuture = _loadCustomUrl();
  }

  Future<void> _ensureInitialized() async {
    await (_initFuture ?? Future.value());
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
        // Render free-tier containers take ~45s to wake from idle sleep
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 65),
        sendTimeout: const Duration(seconds: 45),
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

  Future<Response?> _executeWithRetry(
    String path,
    Future<Response> Function(Dio client) requestFn, {
    int maxRetries = 1,
  }) async {
    await _ensureInitialized();
    int attempts = 0;
    while (attempts <= maxRetries) {
      try {
        return await requestFn(dio);
      } catch (e) {
        attempts++;
        if (attempts > maxRetries) {
          debugPrint('ApiClient error on $path: $e');
          if (kDebugMode && baseUrl != localhostUrl && baseUrl != androidEmulatorUrl) {
            try {
              final fallbackBase = (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
                  ? androidEmulatorUrl
                  : localhostUrl;
              final fallbackDio = Dio(BaseOptions(
                baseUrl: fallbackBase,
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: const Duration(seconds: 10),
              ));
              return await requestFn(fallbackDio);
            } catch (_) {}
          }
          return null;
        }
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    return null;
  }

  Future<Response?> safeGet(String path, {Map<String, dynamic>? queryParameters, int maxRetries = 1}) {
    return _executeWithRetry(
      path,
      (client) => client.get(path, queryParameters: queryParameters),
      maxRetries: maxRetries,
    );
  }

  Future<Response?> safePost(String path, {dynamic data, int maxRetries = 1}) {
    return _executeWithRetry(
      path,
      (client) => client.post(path, data: data),
      maxRetries: maxRetries,
    );
  }

  /// Explicit health check method to test backend connectivity
  Future<Map<String, dynamic>> checkHealth() async {
    await _ensureInitialized();
    try {
      final res = await dio.get('/health');
      if (res.statusCode == 200) {
        return {
          'ok': true,
          'statusCode': 200,
          'data': res.data,
          'message': 'Connected successfully ($baseUrl Online)',
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
        final isCloud = baseUrl.startsWith('https://');
        return {
          'ok': false,
          'message': isCloud
              ? 'Connection timed out at $baseUrl. Render free tier can take ~45s to wake up — please tap Test again.'
              : 'Connection timed out at $baseUrl. Ensure backend server is running on port 8000.',
        };
      }
      return {
        'ok': false,
        'message': 'Network error: ${e.message ?? e.type.name} at $baseUrl',
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
