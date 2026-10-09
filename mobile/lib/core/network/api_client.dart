import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
  }

  void _initDio() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  void setBaseUrl(String newUrl) {
    _overrideUrl = newUrl;
    _initDio();
  }



  Future<Response?> safeGet(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await dio.get(path, queryParameters: queryParameters);
    } catch (_) {
      return null;
    }
  }

  Future<Response?> safePost(String path, {dynamic data}) async {
    try {
      return await dio.post(path, data: data);
    } catch (_) {
      return null;
    }
  }
}

final apiClient = ApiClient();
