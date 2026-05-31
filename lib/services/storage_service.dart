import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService(this._storage);

  final FirebaseStorage _storage;

  Reference listingImageRef(String userId, String listingId, String fileName) {
    return _storage.ref('listings/$userId/$listingId/$fileName');
  }
}