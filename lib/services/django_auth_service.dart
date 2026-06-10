import 'package:uniswap/services/api_client.dart';

/// Authentication service for Django JWT backend.
///
/// Handles login, registration, logout, password reset,
/// and token management via the DRF API.
class DjangoAuthService {
  DjangoAuthService(this._apiClient);

  final ApiClient _apiClient;

  /// Current user data cached after login/me fetch.
  Map<String, dynamic>? _currentUser;

  /// Get cached current user data.
  Map<String, dynamic>? get currentUser => _currentUser;

  /// Register a new user with university email validation.
  ///
  /// [email] must be a valid university email (e.g., @university.edu).
  /// Returns the created user data on success.
  Future<ApiResponse> register({
    required String email,
    required String name,
    required String password,
    required String passwordConfirm,
  }) async {
    final response = await _apiClient.post(
      '/auth/register/',
      body: {
        'email': email,
        'name': name,
        'password': password,
        'password_confirm': passwordConfirm,
      },
      requiresAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      // Auto-login after successful registration
      await login(email: email, password: password);
    }

    return response;
  }

  /// Sign in with email and password.
  ///
  /// On success, stores JWT tokens and fetches user profile.
  Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/token/',
      body: {'email': email, 'password': password},
      requiresAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      await _apiClient.saveTokens(
        accessToken: response.data!['access'] as String,
        refreshToken: response.data!['refresh'] as String,
      );
      // Fetch current user profile
      await fetchCurrentUser();
    }

    return response;
  }

  /// Log out by clearing stored tokens and cached user data.
  Future<void> logout() async {
    await _apiClient.clearTokens();
    _currentUser = null;
  }

  /// Fetch the currently authenticated user's profile.
  Future<ApiResponse> fetchCurrentUser() async {
    final response = await _apiClient.get('/users/me/');

    if (response.isSuccess && response.data != null) {
      _currentUser = response.data;
    }

    return response;
  }

  /// Update the current user's profile fields.
  Future<ApiResponse> updateProfile({
    String? name,
    String? bio,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (bio != null) body['bio'] = bio;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;

    final response = await _apiClient.patch('/users/me/', body: body);

    if (response.isSuccess && response.data != null) {
      _currentUser = response.data;
    }

    return response;
  }

  /// Send a password reset email.
  Future<ApiResponse> sendPasswordReset(String email) async {
    return _apiClient.post(
      '/auth/password-reset/',
      body: {'email': email},
      requiresAuth: false,
    );
  }

  /// Check if the user is currently authenticated (has valid tokens).
  Future<bool> isAuthenticated() async {
    final hasTokens = await _apiClient.hasTokens();
    if (!hasTokens) return false;

    // Verify token is still valid by fetching current user
    final response = await fetchCurrentUser();
    return response.isSuccess;
  }

  /// Fetch user settings (notification preferences, theme, etc.).
  Future<ApiResponse> fetchSettings() async {
    return _apiClient.get('/users/settings/');
  }

  /// Update user settings.
  Future<ApiResponse> updateSettings({
    bool? notificationEnabled,
    String? theme,
    String? language,
  }) async {
    final body = <String, dynamic>{};
    if (notificationEnabled != null) {
      body['notification_enabled'] = notificationEnabled;
    }
    if (theme != null) body['theme'] = theme;
    if (language != null) body['language'] = language;

    return _apiClient.patch('/users/settings/', body: body);
  }

  /// Fetch a specific user's public profile by ID.
  Future<ApiResponse> fetchUserById(int userId) async {
    return _apiClient.get('/users/$userId/');
  }

  /// Fetch a user's average rating.
  Future<ApiResponse> fetchUserRatings(int userId) async {
    return _apiClient.get('/users/$userId/ratings/');
  }
}
