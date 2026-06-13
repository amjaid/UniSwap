import 'package:image_picker/image_picker.dart' show XFile;
import 'package:uniswap/services/api_client.dart';

/// Service for file uploads to the Django backend.
///
/// Handles image uploads for item listings and user avatars.
/// Files are stored via Django's FileField (local storage or S3).
///
/// All methods accept [XFile] from `image_picker` which works on all
/// platforms (web, Android, iOS). Uses `MultipartFile.fromBytes()`
/// internally to avoid `dart:io` dependency on web.
class DjangoStorageService {
  DjangoStorageService(this._apiClient);

  final ApiClient _apiClient;

  /// Upload an image for an item listing.
  ///
  /// [itemId] - The ID of the item to attach the image to.
  /// [file] - The image file to upload (XFile from image_picker).
  /// Returns the uploaded image URL on success.
  Future<ApiResponse> uploadItemImage({
    required int itemId,
    required XFile file,
  }) async {
    return _apiClient.uploadFile(
      '/items/$itemId/upload_image/',
      fieldName: 'image',
      file: file,
    );
  }

  /// Upload a user avatar/profile picture.
  ///
  /// **Deprecated**: Use [DjangoAuthService.updateProfile] with the
  /// `avatarFile` parameter instead, which sends the file as a
  /// multipart PATCH to `/users/me/`.
  ///
  /// [file] - The image file to upload (XFile from image_picker).
  /// Returns the uploaded avatar URL on success.
  @Deprecated('Use DjangoAuthService.updateProfile(avatarFile: file) instead')
  Future<ApiResponse> uploadAvatar({
    required XFile file,
  }) async {
    return _apiClient.uploadFile(
      '/users/me/upload_avatar/',
      fieldName: 'avatar',
      file: file,
    );
  }
}
