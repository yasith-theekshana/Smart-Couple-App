import 'package:cloud_firestore/cloud_firestore.dart';

import '../../authentication/application/auth_repository.dart';
import 'user_profile.dart';

abstract interface class UserProfileRepository {
  Future<void> ensureProfile(AuthSession session, String language);
  Future<UserProfile?> getProfile(String uid);
  Future<bool> exists(String uid);
  Stream<UserProfile?> watchProfile(String uid);
  Future<void> updateProfile(String uid, {String? username, String? language});
}

class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository(this._firestore);
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _document(String uid) =>
      _firestore.collection('users').doc(uid);

  UserProfile? _decode(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return data == null
        ? null
        : UserProfile.fromDocument(
            snapshot.id,
            data,
            pendingWrites: snapshot.metadata.hasPendingWrites,
          );
  }

  @override
  Future<void> ensureProfile(AuthSession session, String language) async {
    if (!session.verified || session.email.isEmpty) {
      throw StateError('Verified account email required');
    }
    final document = _document(session.uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      if (snapshot.exists) return;
      final emailName = session.email.split('@').first.trim();
      final username =
          normalizeUsername(session.name ?? '') ??
          normalizeUsername(emailName) ??
          'SmartCouple';
      final profile = UserProfile(
        uid: session.uid,
        username: username,
        email: session.email,
        preferredLanguage: profileLanguages.contains(language)
            ? language
            : 'en',
      );
      transaction.set(document, profile.toDocument());
    });
  }

  @override
  Future<UserProfile?> getProfile(String uid) async => _decode(
    await _document(uid).get(const GetOptions(source: Source.server)),
  );

  @override
  Future<bool> exists(String uid) async =>
      (await _document(uid).get(const GetOptions(source: Source.server)))
          .exists;

  @override
  Stream<UserProfile?> watchProfile(String uid) => _document(uid)
      .snapshots(includeMetadataChanges: true)
      .where((snapshot) => snapshot.exists || !snapshot.metadata.isFromCache)
      .map(_decode);

  @override
  Future<void> updateProfile(
    String uid, {
    String? username,
    String? language,
  }) async {
    final name = username == null ? null : normalizeUsername(username);
    if ((username != null && name == null) ||
        (language != null && !profileLanguages.contains(language))) {
      throw ArgumentError('Invalid username or preferred language');
    }
    if (name == null && language == null) return;
    final document = _document(uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      if (!snapshot.exists) throw StateError('Profile no longer exists');
      transaction.update(document, {
        'username': ?name,
        'preferredLanguage': ?language,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
