import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniswap/services/api_client.dart';
import 'package:uniswap/services/chat_service.dart';
import 'package:uniswap/services/django_auth_service.dart';
import 'package:uniswap/services/django_notification_service.dart';
import 'package:uniswap/services/django_storage_service.dart';
import 'package:uniswap/services/item_service.dart';
import 'package:uniswap/services/transaction_service.dart';

/// Riverpod providers for all Django backend services.
///
/// Replace Firebase providers with these when migrating.
/// Usage: ref.watch(apiClientProvider) etc.

// ──────────────────────────────────────────────
// Core
// ──────────────────────────────────────────────

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// ──────────────────────────────────────────────
// Auth
// ──────────────────────────────────────────────

final djangoAuthServiceProvider = Provider<DjangoAuthService>((ref) {
  return DjangoAuthService(ref.read(apiClientProvider));
});

/// Auth state provider - emits the current user data or null.
/// Uses polling to check token validity on app start.
final authStateProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authService = ref.read(djangoAuthServiceProvider);
  final isAuth = await authService.isAuthenticated();
  if (isAuth) {
    return authService.currentUser;
  }
  return null;
});

// ──────────────────────────────────────────────
// Items
// ──────────────────────────────────────────────

final itemServiceProvider = Provider<ItemService>((ref) {
  return ItemService(ref.read(apiClientProvider));
});

// ──────────────────────────────────────────────
// Transactions
// ──────────────────────────────────────────────

final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService(ref.read(apiClientProvider));
});

// ──────────────────────────────────────────────
// Chat
// ──────────────────────────────────────────────

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.read(apiClientProvider));
});

// ──────────────────────────────────────────────
// Notifications
// ──────────────────────────────────────────────

final djangoNotificationServiceProvider =
    Provider<DjangoNotificationService>((ref) {
  return DjangoNotificationService(ref.read(apiClientProvider));
});

// ──────────────────────────────────────────────
// Storage
// ──────────────────────────────────────────────

final djangoStorageServiceProvider = Provider<DjangoStorageService>((ref) {
  return DjangoStorageService(ref.read(apiClientProvider));
});
