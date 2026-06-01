import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import '../config/app_config.dart';
import 'storage_service.dart';

/// Singleton API Service using Dio with interceptors
/// - AuthInterceptor: injects JWT token
/// - ErrorInterceptor: handles 401 auto-logout, network errors
/// - LogInterceptor: debug-only request/response logging
class ApiService extends GetxService {
  static ApiService get to => Get.find<ApiService>();

  late Dio _dio;

  Dio get dio => _dio;

  Future<ApiService> init() async {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // ── Add Interceptors ────────────────────────────────────────────────────
    _dio.interceptors.addAll([
      _AuthInterceptor(),
      _ErrorInterceptor(),
      if (kDebugMode) _LoggingInterceptor(),
    ]);

    return this;
  }

  // ─── Convenience Methods ────────────────────────────────────────────────────

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(
    String path, {
    dynamic data,
  }) async {
    return _dio.post(path, data: data);
  }

  Future<Response> put(
    String path, {
    dynamic data,
  }) async {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return _dio.delete(path);
  }

  /// Upload image as multipart form data
  Future<Response> uploadImage(
    String path, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? extraFields,
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
      if (extraFields != null) ...extraFields,
    });

    return _dio.post(
      path,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// INTERCEPTORS
// ═══════════════════════════════════════════════════════════════════════════════

/// Injects JWT Bearer token into every request automatically
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = StorageService.to.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Handles error responses:
/// - 401: Auto-logout and redirect to login
/// - Network errors: Show snackbar
/// - Server errors: Show error message
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String message = 'Something went wrong';

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout. Please try again.';
    } else if (err.type == DioExceptionType.connectionError) {
      message = 'No internet connection.';
    } else if (err.response != null) {
      final statusCode = err.response!.statusCode;
      final responseData = err.response!.data;

      if (statusCode == 401) {
        // Token expired or invalid — auto logout
        message = 'Session expired. Please login again.';
        _handleUnauthorized();
      } else if (responseData is Map && responseData['message'] != null) {
        message = responseData['message'];
      } else if (statusCode == 500) {
        message = 'Server error. Please try again later.';
      }
    }

    // Show snackbar for user-facing errors
    if (Get.isSnackbarOpen != true) {
      Get.snackbar(
        'Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }

    handler.next(err);
  }

  void _handleUnauthorized() {
    // Clear stored data and redirect to login
    StorageService.to.clearAll();
    Get.offAllNamed('/login');
  }
}

/// Debug-only logging interceptor
/// Prints request/response details to console
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('┌─── API Request ───────────────────────────');
    debugPrint('│ ${options.method} ${options.uri}');
    if (options.data != null) {
      debugPrint('│ Body: ${options.data}');
    }
    debugPrint('└───────────────────────────────────────────');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('┌─── API Response ──────────────────────────');
    debugPrint('│ ${response.statusCode} ${response.requestOptions.uri}');
    debugPrint('└───────────────────────────────────────────');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('┌─── API Error ─────────────────────────────');
    debugPrint('│ ${err.response?.statusCode} ${err.requestOptions.uri}');
    debugPrint('│ ${err.message}');
    debugPrint('└───────────────────────────────────────────');
    handler.next(err);
  }
}
