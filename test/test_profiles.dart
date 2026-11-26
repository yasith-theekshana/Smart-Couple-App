import 'dart:async';

import 'package:smart_couple/features/authentication/application/auth_repository.dart';
import 'package:smart_couple/features/profile/data/user_profile.dart';
import 'package:smart_couple/features/profile/data/user_profile_repository.dart';

class TestProfiles implements UserProfileRepository {
  final profiles = <String, UserProfile>{};
  final _updates = StreamController<UserProfile>.broadcast();
  final activeListeners = <String>{};
  Object? loadError;

  @override
  Future<void> ensureProfile(AuthSession session, String language) async {
    if (loadError case final error?) throw error;
    profiles.putIfAbsent(
      session.uid,
      () => UserProfile(
        uid: session.uid,
        username: session.name ?? 'Camille',
        email: session.email,
        preferredLanguage: language,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
  }

  @override
  Future<bool> exists(String uid) async => profiles.containsKey(uid);

  @override
  Future<UserProfile?> getProfile(String uid) async => profiles[uid];

  @override
  Stream<UserProfile?> watchProfile(String uid) => Stream.multi((output) {
    activeListeners.add(uid);
    output.add(profiles[uid]);
    final subscription = _updates.stream
        .where((profile) => profile.uid == uid)
        .listen(output.add, onDone: output.close);
    output.onCancel = () {
      activeListeners.remove(uid);
      return subscription.cancel();
    };
  });

  @override
  Future<void> updateProfile(
    String uid, {
    String? username,
    String? language,
  }) async {
    final profile = profiles[uid]!.copyWith(
      username: username,
      preferredLanguage: language,
    );
    profiles[uid] = profile;
    _updates.add(profile);
  }

  Future<void> close() => _updates.close();
}
