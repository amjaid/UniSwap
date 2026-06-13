import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uniswap/services/api_client.dart';

/// Service for notification operations.
///
/// Communicates with the Django notifications API endpoints.
/// The Flutter side polls for unread notifications periodically.
///
/// Features:
/// - Singleton polling timer (only one timer exists at any time)
/// - 30-second polling interval
/// - Exponential backoff on 429 (Too Many Requests) responses
/// - Request deduplication (prevents concurrent calls to the same endpoint)
class DjangoNotificationService {
  DjangoNotificationService(this._apiClient);

  final ApiClient _apiClient;

  /// Base polling interval for unread notifications (in seconds).
  static const int _basePollIntervalSeconds = 30;

  /// Maximum backoff delay in seconds (5 minutes).
  static const int _maxBackoffSeconds = 300;

  Timer? _pollTimer;
  int _unreadCount = 0;
  final List<void Function(int unreadCount)> _listeners = [];

  /// Whether a poll request is currently in flight (deduplication).
  bool _isPolling = false;

  /// Current backoff interval in seconds.
  int _currentBackoffSeconds = _basePollIntervalSeconds;

  // ──────────────────────────────────────────────
  // Notifications
  // ──────────────────────────────────────────────

  /// Fetch notifications for the current user.
  Future<ApiResponse> fetchNotifications({int page = 1}) async {
    return _apiClient.get(
      '/notifications/',
      queryParams: {'page': page.toString()},
    );
  }

  /// Mark a specific notification as read.
  Future<ApiResponse> markAsRead(int notificationId) async {
    return _apiClient.post('/notifications/$notificationId/mark_read/');
  }

  /// Mark all notifications as read for the current user.
  Future<ApiResponse> markAllAsRead() async {
    return _apiClient.post('/notifications/mark_all_read/');
  }

  /// Get the count of unread notifications.
  ///
  /// Backend endpoint: GET /api/notifications/unread/
  /// Returns: {"unread_count": 5, "notifications": [...]}
  Future<ApiResponse> fetchUnreadCount() async {
    return _apiClient.get('/notifications/unread/');
  }

  // ──────────────────────────────────────────────
  // Polling with Exponential Backoff
  // ──────────────────────────────────────────────

  /// Start polling for unread notification count.
  ///
  /// Only one timer is ever created. If called multiple times, the existing
  /// timer continues running. New listeners are registered but no duplicate
  /// timer is started.
  void startPolling({void Function(int unreadCount)? onUpdate}) {
    if (onUpdate != null) {
      _listeners.add(onUpdate);
    }

    if (_pollTimer == null) {
      _resetBackoff();
      _scheduleNextPoll();
      // Immediate first fetch
      _pollUnreadCount();
    }
  }

  /// Stop polling for notifications.
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isPolling = false;
  }

  /// Get the latest cached unread count.
  int get unreadCount => _unreadCount;

  /// Register a listener for unread count updates.
  void addListener(void Function(int unreadCount) listener) {
    _listeners.add(listener);
  }

  /// Remove a listener.
  void removeListener(void Function(int unreadCount) listener) {
    _listeners.remove(listener);
  }

  /// Schedule the next poll using the current backoff interval.
  void _scheduleNextPoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer(
      Duration(seconds: _currentBackoffSeconds),
      _pollUnreadCount,
    );
  }

  /// Reset backoff to the base interval.
  void _resetBackoff() {
    _currentBackoffSeconds = _basePollIntervalSeconds;
  }

  /// Apply exponential backoff when a 429 is received.
  ///
  /// Doubles the interval each time, up to [_maxBackoffSeconds].
  /// If the backend provides a suggested wait time in the response,
  /// uses that instead (capped at [_maxBackoffSeconds]).
  void _applyBackoff({int? suggestedSeconds}) {
    if (suggestedSeconds != null && suggestedSeconds > 0) {
      _currentBackoffSeconds = min(suggestedSeconds, _maxBackoffSeconds);
    } else {
      _currentBackoffSeconds = min(
        _currentBackoffSeconds * 2,
        _maxBackoffSeconds,
      );
    }
    if (kDebugMode) {
      debugPrint('[NotificationService] Backoff applied: '
          'next poll in $_currentBackoffSeconds seconds');
    }
  }

  Future<void> _pollUnreadCount() async {
    // Deduplication: skip if a poll is already in flight
    if (_isPolling) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Skipping poll — already in flight');
      }
      _scheduleNextPoll();
      return;
    }

    _isPolling = true;

    try {
      final response = await fetchUnreadCount();

      if (response.isSuccess && response.data != null) {
        // Success: reset backoff and update count
        _resetBackoff();
        final count = response.data!['unread_count'] as int? ?? 0;
        _unreadCount = count;
        for (final listener in _listeners) {
          listener(count);
        }
      } else if (response.statusCode == 429) {
        // Rate limited: extract suggested wait time from error detail
        int? suggestedSeconds;
        if (response.error != null) {
          // Parse "Expected available in 1172 seconds." from the error message
          final match = RegExp(r'(\d+)\s*seconds').firstMatch(response.error!);
          if (match != null) {
            suggestedSeconds = int.tryParse(match.group(1)!);
          }
        }
        _applyBackoff(suggestedSeconds: suggestedSeconds);
        if (kDebugMode) {
          debugPrint('[NotificationService] Rate limited (429). '
              '${suggestedSeconds != null ? "Suggested wait: $suggestedSeconds s. " : ""}'
              'Backoff: $_currentBackoffSeconds s');
        }
      } else {
        // Other error: apply mild backoff
        _applyBackoff();
        if (kDebugMode) {
          debugPrint('[NotificationService] Poll error: ${response.error}');
        }
      }
    } catch (e) {
      _applyBackoff();
      if (kDebugMode) {
        debugPrint('[NotificationService] Polling error: $e');
      }
    } finally {
      _isPolling = false;
      // Schedule the next poll (using Timer, not Timer.periodic, so the
      // interval is dynamic based on backoff state)
      _scheduleNextPoll();
    }
  }

  /// Dispose all resources.
  void dispose() {
    stopPolling();
    _listeners.clear();
  }
}
