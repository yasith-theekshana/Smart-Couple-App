import 'package:cloud_firestore/cloud_firestore.dart';

const maxUsernameLength = 50;
const profileLanguages = {'en', 'fr'};

String? normalizeUsername(String value) {
  final name = value.trim();
  return name.isEmpty || name.length > maxUsernameLength ? null : name;
}

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.username,
    required this.email,
    required this.preferredLanguage,
    this.coupleId,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromDocument(
    String id,
    Map<String, dynamic> data, {
    bool pendingWrites = false,
  }) {
    final uid = data['uid'];
    final username = data['username'];
    final email = data['email'];
    final coupleId = data['coupleId'];
    final language = data['preferredLanguage'];
    if (uid != id ||
        uid is! String ||
        username is! String ||
        normalizeUsername(username) == null ||
        email is! String ||
        email.isEmpty ||
        (coupleId != null && coupleId is! String) ||
        !profileLanguages.contains(language)) {
      throw const FormatException('Invalid user profile fields');
    }
    DateTime? readDate(String field) {
      final timestamp = data[field];
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp == null && pendingWrites) return null;
      throw FormatException('Missing or invalid profile timestamp: $field');
    }

    return UserProfile(
      uid: uid,
      username: username,
      email: email,
      coupleId: coupleId as String?,
      preferredLanguage: language as String,
      createdAt: readDate('createdAt'),
      updatedAt: readDate('updatedAt'),
    );
  }

  final String uid;
  final String username;
  final String email;
  final String? coupleId;
  final String preferredLanguage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toDocument() => {
    'uid': uid,
    'username': username,
    'email': email,
    'coupleId': coupleId,
    'preferredLanguage': preferredLanguage,
    'createdAt': createdAt == null
        ? FieldValue.serverTimestamp()
        : Timestamp.fromDate(createdAt!),
    'updatedAt': updatedAt == null
        ? FieldValue.serverTimestamp()
        : Timestamp.fromDate(updatedAt!),
  };

  UserProfile copyWith({String? username, String? preferredLanguage}) =>
      UserProfile(
        uid: uid,
        username: username ?? this.username,
        email: email,
        coupleId: coupleId,
        preferredLanguage: preferredLanguage ?? this.preferredLanguage,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
