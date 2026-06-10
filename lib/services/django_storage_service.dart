import 'dart:io';

import 'package:uniswap/services/api_client.dart';

/// Service for file uploads to the Django backend.
///
/// Handles image uploads for item listings and user avatars.
/// Files are stored via Django's FileField (local storage or S3).
class DjangoStorageService {
  DjangoStorageService(this._apiClient);

  final ApiClient _apiClient;

  /// Upload an image for an item listing.
  ///
  /// [itemId] - The ID of the item to attach the image to.
  /// [file] - The image file to upload.
  /// Returns the uploaded image URL on success.
  Future<ApiResponse> uploadItemImage({
    required int itemId,
    required File file,
  }) async {
    return _apiClient.uploadFile(
      '/items/$itemId/upload_image/',
      fieldName: 'image',
      file: file,
    );
  }

  /// Upload a user avatar/profile picture.
  ///
  /// [file] - The image file to upload.
  /// Returns the uploaded avatar URL on success.
  Future<ApiResponse> uploadAvatar({
    required File file,
  }) async {
    return _apiClient.uploadFile(
      '/users/me/upload_avatar/',
      fieldName: 'avatar',
      file: file,
    );
  }
}
