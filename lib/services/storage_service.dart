import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService(this._storage);

  final FirebaseStorage _storage;

  Reference listingImageRef(String userId, String listingId, String fileName) {
    return _storage.ref('listings/$userId/$listingId/$fileName');
  }

  Reference profileImageRef(String userId, String fileName) {
    return _storage.ref('profiles/$userId/$fileName');
  }

  Future<String> uploadProfileImage({
    required String userId,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    final ref = profileImageRef(userId, fileName);
    final metadata = SettableMetadata(contentType: contentType);
    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }
}