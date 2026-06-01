import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uniswap/models/chat_message.dart';
import 'package:uniswap/models/conversation_thread.dart';

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

  Future<void> updateFcmToken({
    required String userId,
    required String token,
  }) {
    return _firestore.collection('users').doc(userId).set({
      'fcm_token': token,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<ConversationThread>> streamThreads(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('last_timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final unreadCounts = (data['unread_counts'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
            ) ??
            {};
        return ConversationThread(
          id: doc.id,
          swapId: data['swap_id'] as String? ?? doc.id,
          contactName: data['other_user_name'] as String? ?? 'UTM Student',
          contactAvatarUrl: data['other_user_avatar'] as String? ??
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
          isVerified: data['other_user_verified'] as bool? ?? false,
          lastMessage: data['last_message'] as String? ?? 'Start chatting',
          lastTimestamp: (data['last_timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          unreadCount: unreadCounts[userId] ?? (data['unread_count'] as int? ?? 0),
          role: threadCategoryFromString(data['role'] as String?),
        );
      }).toList();
    });
  }

  Stream<List<ChatMessage>> streamMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage(
          id: doc.id,
          senderId: data['sender_id'] as String? ?? '',
          text: data['text'] as String? ?? '',
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  Stream<Map<String, dynamic>> streamConversationMeta(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .snapshots()
        .map((snapshot) => snapshot.data() ?? {});
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    final conversationSnap = await conversationRef.get();
    final conversationData = conversationSnap.data() ?? {};
    final participants = (conversationData['participants'] as List?)
            ?.whereType<String>()
            .toList() ??
        [];

    final unreadCounts = (conversationData['unread_counts'] as Map?)?.map(
          (key, value) => MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
        ) ??
        {};

    for (final participant in participants) {
      if (participant == senderId) {
        unreadCounts[participant] = 0;
      } else {
        unreadCounts[participant] = (unreadCounts[participant] ?? 0) + 1;
      }
    }

    final payload = {
      'sender_id': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await messageRef.set(payload);
    await conversationRef.set({
      'last_message': text,
      'last_timestamp': FieldValue.serverTimestamp(),
      if (unreadCounts.isNotEmpty) 'unread_counts': unreadCounts,
    }, SetOptions(merge: true));
  }

  Future<String> ensureListingConversation({
    required String conversationId,
    required String userId,
    required String otherUserId,
    required String otherUserName,
  }) async {
    final ref = _firestore.collection('conversations').doc(conversationId);
    final snapshot = await ref.get();
    if (!snapshot.exists) {
      await ref.set({
        'participants': [userId, otherUserId],
        'swap_id': conversationId,
        'role': 'buying',
        'other_user_name': otherUserName,
        'other_user_avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
        'other_user_verified': false,
        'last_message': 'Start chatting',
        'last_timestamp': FieldValue.serverTimestamp(),
        'unread_counts': {
          userId: 0,
          otherUserId: 0,
        },
      }, SetOptions(merge: true));
    }
    return ref.id;
  }

  Future<void> setTypingStatus({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) {
    return _firestore.collection('conversations').doc(conversationId).set({
      'typing': {userId: isTyping},
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setPresenceStatus({
    required String conversationId,
    required String userId,
    required bool isOnline,
  }) {
    return _firestore.collection('conversations').doc(conversationId).set({
      'presence': {userId: isOnline},
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markConversationRead({
    required String conversationId,
    required String userId,
  }) async {
    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    final conversationSnap = await conversationRef.get();
    final data = conversationSnap.data() ?? {};
    final unreadCounts = (data['unread_counts'] as Map?)?.map(
          (key, value) => MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
        ) ??
        {};

    if (unreadCounts[userId] == 0) return;
    unreadCounts[userId] = 0;
    await conversationRef.set({'unread_counts': unreadCounts}, SetOptions(merge: true));
  }

  Future<List<String>> fetchFaculties() async {
    final snapshot = await _firestore.collection('faculties').get();
    return snapshot.docs
        .map((doc) => doc.data()['name'])
        .whereType<String>()
        .toList();
  }
}
