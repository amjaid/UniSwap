import 'package:uniswap/services/api_client.dart';

/// Resolve an image path to a full absolute URL suitable for NetworkImage.
///
/// The Django backend may return relative paths like `/media/images/abc.jpg`
/// instead of full URLs. This helper converts them to absolute URLs by
/// prepending the API base URL.
///
/// If [imagePath] is already absolute (starts with http:// or https://),
/// it is returned unchanged. Returns an empty string for null/empty input.
String getFullImageUrl(String? imagePath) {
  if (imagePath == null || imagePath.isEmpty) return '';
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return imagePath;
  }

  // Prepend the API base URL (strip the /api suffix to get the server root)
  final base = ApiClient.defaultBaseUrl;
  final baseUrl = base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
  return '$baseUrl${imagePath.startsWith('/') ? imagePath : '/$imagePath'}';
}
