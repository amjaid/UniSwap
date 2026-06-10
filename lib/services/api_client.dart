import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:shared_preferences/shared_preferences.dart';

/// Central HTTP client for all API calls to the Django backend.
///
/// Features:
/// - Platform-aware base URL (web → localhost, Android → 10.0.2.2, iOS → localhost)
/// - JWT token storage and automatic refresh
/// - Error handling with typed exceptions
/// - Request/response logging in debug mode
///
/// The base URL can be overridden via the [baseUrl] parameter or by setting
/// the `API_BASE_URL` environment variable in a `.env` file (requires flutter_dotenv).
class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl})
      : _httpClient = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? ApiClient.defaultBaseUrl;

  /// Returns the platform-appropriate default API base URL.
  ///
  /// - **Web** → `http://localhost:8000/api`
  /// - **Android** → `http://10.0.2.2:8000/api` (emulator loopback to host)
  /// - **iOS/macOS** → `http://localhost:8000/api`
  ///
  /// Override by passing a custom [baseUrl] to the constructor or by
  /// setting `API_BASE_URL` in a `.env` file.
  static String get defaultBaseUrl {
    if (kIsWeb) {
      // Web browsers run on the host machine, so localhost works directly.
      return 'http://localhost:8000/api';
    }
    // Android emulator uses 10.0.2.2 to reach the host machine.
    // iOS simulator and desktop use localhost.
    // Physical devices would need the host machine's LAN IP.
    return 'http://10.0.2.2:8000/api';
  }

  final http.Client _httpClient;
  final String _baseUrl;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  // ──────────────────────────────────────────────
  // Token Management
  // ──────────────────────────────────────────────

  /// Retrieve stored access token.
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// Retrieve stored refresh token.
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// Persist JWT token pair after login/refresh.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  /// Clear stored tokens on logout.
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  /// Check if user has stored tokens (i.e., is logged in).
  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ──────────────────────────────────────────────
  // HTTP Methods
  // ──────────────────────────────────────────────

  /// Perform a GET request.
  Future<ApiResponse> get(
    String path, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(path, queryParams);
    final headers = await _buildHeaders(requiresAuth);
    return _execute(() => _httpClient.get(uri, headers: headers), path);
  }

  /// Perform a POST request.
  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(path);
    final headers = await _buildHeaders(requiresAuth);
    return _execute(
      () => _httpClient.post(uri, headers: headers, body: jsonEncode(body)),
      path,
    );
  }

  /// Perform a PATCH request.
  Future<ApiResponse> patch(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(path);
    final headers = await _buildHeaders(requiresAuth);
    return _execute(
      () => _httpClient.patch(uri, headers: headers, body: jsonEncode(body)),
      path,
    );
  }

  /// Perform a PUT request.
  Future<ApiResponse> put(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(path);
    final headers = await _buildHeaders(requiresAuth);
    return _execute(
      () => _httpClient.put(uri, headers: headers, body: jsonEncode(body)),
      path,
    );
  }

  /// Perform a DELETE request.
  Future<ApiResponse> delete(
    String path, {
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(path);
    final headers = await _buildHeaders(requiresAuth);
    return _execute(() => _httpClient.delete(uri, headers: headers), path);
  }

  /// Upload a file via multipart request.
  ///
  /// Accepts an [XFile] from `image_picker` which works on all platforms
  /// (web, Android, iOS). Uses `MultipartFile.fromBytes()` internally
  /// instead of `fromPath()` to avoid `dart:io` dependency on web.
  ///
  /// [path] - API endpoint path (e.g., '/items/1/upload_image/')
  /// [fieldName] - The form field name expected by the backend (e.g., 'image', 'avatar')
  /// [file] - The image file to upload (XFile from image_picker)
  /// [additionalFields] - Optional extra form fields to include
  /// [method] - HTTP method to use (defaults to POST)
  Future<ApiResponse> uploadFile(
    String path, {
    required String fieldName,
    required XFile file,
    Map<String, String>? additionalFields,
    String method = 'POST',
  }) async {
    final uri = _buildUri(path);
    final request = http.MultipartRequest(method, uri);

    // Attach auth header
    final token = await getAccessToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Read file bytes (works on all platforms including web)
    final bytes = await file.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: file.name,
      ),
    );

    // Attach additional fields
    if (additionalFields != null) {
      request.fields.addAll(additionalFields);
    }

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    return _processResponse(response, path);
  }

  /// Send a multipart PATCH request with a file and optional JSON fields.
  ///
  /// This is used for updating user profiles with avatar uploads.
  /// The file is sent as multipart/form-data along with any additional
  /// text fields. Uses `MultipartFile.fromBytes()` for web compatibility.
  ///
  /// [path] - API endpoint path (e.g., '/users/me/')
  /// [fieldName] - The form field name for the file (e.g., 'avatar')
  /// [file] - The file to upload (XFile from image_picker)
  /// [fields] - Optional additional text fields to include in the form
  Future<ApiResponse> patchMultipart(
    String path, {
    required String fieldName,
    required XFile file,
    Map<String, String>? fields,
  }) async {
    final uri = _buildUri(path);
    final request = http.MultipartRequest('PATCH', uri);

    // Attach auth header
    final token = await getAccessToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Read file bytes (works on all platforms including web)
    final bytes = await file.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: file.name,
      ),
    );

    // Attach additional text fields
    if (fields != null) {
      request.fields.addAll(fields);
    }

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    return _processResponse(response, path);
  }

  // ──────────────────────────────────────────────
  // Internal Helpers
  // ──────────────────────────────────────────────

  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    final uri = Uri.parse('$_baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Future<Map<String, String>> _buildHeaders(bool requiresAuth) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<ApiResponse> _execute(
    Future<http.Response> Function() request,
    String path,
  ) async {
    try {
      final response = await request();
      return _processResponse(response, path);
    } on SocketException {
      return ApiResponse.error(
        'No internet connection. Please check your network.',
      );
    } on http.ClientException {
      return ApiResponse.error('Connection failed. Please try again.');
    } on FormatException {
      return ApiResponse.error('Invalid response from server.');
    } catch (e) {
      debugPrint('ApiClient error: $e');
      return ApiResponse.error('An unexpected error occurred.');
    }
  }

  Future<ApiResponse> _processResponse(
    http.Response response,
    String path,
  ) async {
    if (kDebugMode) {
      debugPrint('${response.statusCode} ${response.request?.url}');
      if (response.body.isNotEmpty && response.body.length < 2000) {
        debugPrint('Response body: ${response.body}');
      }
    }

    // Try to parse body as JSON
    Map<String, dynamic>? body;
    try {
      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          body = decoded;
        }
      }
    } catch (_) {
      // Body is not JSON
    }

    // Handle 401 - try token refresh
    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        // Retry the original request with new token
        final headers = await _buildHeaders(true);
        return _execute(
          () => _httpClient.get(
            Uri.parse('$_baseUrl$path'),
            headers: headers,
          ),
          path,
        );
      }

      // Refresh failed - clear tokens
      await clearTokens();
      return ApiResponse.error(
        'Session expired. Please sign in again.',
        statusCode: 401,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse.success(body, statusCode: response.statusCode);
    }

    // Extract error message from response
    String errorMessage = 'Request failed (${response.statusCode}).';
    if (body != null) {
      // DRF returns field-level errors
      final firstError = body.values.firstWhere(
        (v) => v is List && v.isNotEmpty,
        orElse: () => null,
      );
      if (firstError != null) {
        errorMessage = (firstError as List).first.toString();
      } else if (body.containsKey('detail')) {
        errorMessage = body['detail'].toString();
      }
    }

    if (kDebugMode) {
      debugPrint('[ApiClient] Error $path: $errorMessage');
    }

    return ApiResponse.error(errorMessage, statusCode: response.statusCode);
  }

  /// Attempt to refresh the JWT access token using the stored refresh token.
  Future<bool> _tryRefreshToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final uri = _buildUri('/auth/token/refresh/');
      final response = await _httpClient.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await saveTokens(
          accessToken: data['access'] as String,
          refreshToken: data['refresh'] as String? ?? refreshToken,
        );
        return true;
      }
    } catch (_) {
      // Refresh failed
    }

    return false;
  }
}

/// Typed response wrapper for API calls.
class ApiResponse {
  const ApiResponse._({
    this.data,
    this.error,
    this.statusCode,
    this.isSuccess = false,
  });

  factory ApiResponse.success(Map<String, dynamic>? data, {int? statusCode}) {
    return ApiResponse._(
      data: data,
      statusCode: statusCode,
      isSuccess: true,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse._(
      error: message,
      statusCode: statusCode,
      isSuccess: false,
    );
  }

  /// Parsed JSON response body.
  final Map<String, dynamic>? data;

  /// Error message if request failed.
  final String? error;

  /// HTTP status code.
  final int? statusCode;

  /// Whether the request was successful.
  final bool isSuccess;
}
