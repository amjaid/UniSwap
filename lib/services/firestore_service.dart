import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> createUserProfile({
    required String userId,
    required String fullName,
    required String email,
    required String phone,
    required String faculty,
    required String campus,
  }) {
    return _firestore.collection('users').doc(userId).set({
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'faculty': faculty,
      'campus': campus,
      'created_at': FieldValue.serverTimestamp(),
      'is_banned': false,
    }, SetOptions(merge: true));
  }

  Future<List<String>> fetchFaculties() async {
    final snapshot = await _firestore.collection('faculties').get();
    return snapshot.docs
        .map((doc) => doc.data()['name'])
        .whereType<String>()
        .toList();
  }
}
