import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uniswap/services/api_client.dart';

/// Service for in-app notification operations.
///
/// Communicates with the Django notifications API endpoints.
/// Uses polling to check for new notifications since DRF is REST-based.
class DjangoNotificationService {
  DjangoNotificationService(this._apiClient);

  final ApiClient _apiClient;

  /// Polling interval for unread notifications (in seconds).
  static const int _pollIntervalSeconds = 30;

  Timer? _pollingTimer;

  /// Callback invoked when unread count changes.
  void Function(int unreadCount)? onUnreadCountChanged;

  // ──────────────────────────────────────────────
  // Notification CRUD
  // ──────────────────────────────────────────────

  /// Fetch the current user's notifications.
  Future<ApiResponse> fetchNotifications({int page = 1}) async {
    return _apiClient.get(
      '/notifications/',
      queryParams: {'page': page.toString()},
    );
  }

  /// Fetch only unread notifications with count.
  Future<ApiResponse> fetchUnreadNotifications() async {
    return _apiClient.get('/notifications/unread/');
  }

  /// Mark a single notification as read.
  Future<ApiResponse> markAsRead(int notificationId) async {
    return _apiClient.post('/notifications/$notificationId/mark_read/');
  }

  /// Mark all notifications as read for the current user.
  Future<ApiResponse> markAllAsRead() async {
    return _apiClient.post('/notifications/mark_all_read/');
  }

  // ──────────────────────────────────────────────
  // Polling for Unread Count
  // ──────────────────────────────────────────────

  /// Start polling for unread notification count.
  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: _pollIntervalSeconds),
      (_) => _checkUnreadCount(),
    );
    // Immediate first check
    _checkUnreadCount();
  }

  /// Stop polling for notifications.
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _checkUnreadCount() async {
    try {
      final response = await fetchUnreadNotifications();
      if (response.isSuccess && response.data != null) {
        final count = response.data!['unread_count'] as int? ?? 0;
        onUnreadCountChanged?.call(count);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Notification polling error: $e');
      }
    }
  }

  /// Dispose the polling timer.
  void dispose() {
    stopPolling();
  }
}
