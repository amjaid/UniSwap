import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniswap/repositories/listing_repository.dart';
import 'package:uniswap/repositories/swap_repository.dart';
import 'package:uniswap/services/api_client.dart';
import 'package:uniswap/services/chat_service.dart';
import 'package:uniswap/services/django_auth_service.dart';
import 'package:uniswap/services/django_notification_service.dart';
import 'package:uniswap/services/django_storage_service.dart';
import 'package:uniswap/services/item_service.dart';
import 'package:uniswap/services/transaction_service.dart';

/// API client singleton.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Auth service.
final djangoAuthServiceProvider = Provider<DjangoAuthService>((ref) {
  return DjangoAuthService(ref.read(apiClientProvider));
});

/// Item service.
final itemServiceProvider = Provider<ItemService>((ref) {
  return ItemService(ref.read(apiClientProvider));
});

/// Chat service.
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.read(apiClientProvider));
});

/// Transaction service.
final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService(ref.read(apiClientProvider));
});

/// Notification service.
final notificationServiceProvider = Provider<DjangoNotificationService>((ref) {
  return DjangoNotificationService(ref.read(apiClientProvider));
});

/// Storage service (for file uploads).
final storageServiceProvider = Provider<DjangoStorageService>((ref) {
  return DjangoStorageService(ref.read(apiClientProvider));
});

/// Listing repository (in-memory cache).
final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  return ListingRepository(ref.read(itemServiceProvider));
});

/// Swap repository (in-memory cache for transactions).
final swapRepositoryProvider = Provider<SwapRepository>((ref) {
  return SwapRepository(ref.read(transactionServiceProvider));
});
