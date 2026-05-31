import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> createUserProfile({
    required String userId,
    required String fullName,
    required String username,
    required String email,
    required String phone,
    required String faculty,
    required String campus,
  }) {
    return _firestore.collection('users').doc(userId).set({
      'full_name': fullName,
      'username': username,
      'email': email,
      'phone': phone,
      'faculty': faculty,
      'campus': campus,
      'created_at': FieldValue.serverTimestamp(),
      'is_banned': false,
    }, SetOptions(merge: true));
  }

  Future<bool> isUsernameAvailable(String username, {String? currentUserId}) async {
    final normalized = username.toLowerCase();
    final snapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: normalized)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return true;
    if (currentUserId == null) return false;
    return snapshot.docs.first.id == currentUserId;
  }

  Future<void> updateUsername({
    required String userId,
    required String username,
  }) {
    return _firestore.collection('users').doc(userId).set({
      'username': username.toLowerCase(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateProfilePhoto({
    required String userId,
    required String photoUrl,
  }) {
    return _firestore.collection('users').doc(userId).set({
      'photo_url': photoUrl,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> fetchUserProfile({required String userId}) async {
    final snapshot = await _firestore.collection('users').doc(userId).get();
    return snapshot.data();
  }

  Future<List<String>> fetchFaculties() async {
    final snapshot = await _firestore.collection('faculties').get();
    return snapshot.docs
        .map((doc) => doc.data()['name'])
        .whereType<String>()
        .toList();
  }
}
