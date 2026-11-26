import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/demo_state.dart';
import '../../authentication/application/auth_repository.dart';
import '../data/user_profile.dart';
import '../data/user_profile_repository.dart';

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);
final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => FirestoreUserProfileRepository(ref.watch(firestoreProvider)),
);

final activeProfileProvider = StreamProvider.autoDispose<UserProfile?>((ref) {
  final uid = ref.watch(
    authSessionProvider.select((state) {
      final session = state.asData?.value;
      return session?.verified == true ? session!.uid : null;
    }),
  );
  if (uid == null) return Stream<UserProfile?>.value(null);
  final session = ref.read(authSessionProvider).requireValue!;
  final repository = ref.watch(userProfileRepositoryProvider);
  final language = ref.read(localeProvider)?.languageCode ?? 'en';
  final controller = StreamController<UserProfile?>();
  StreamSubscription<UserProfile?>? subscription;
  ref.onDispose(() {
    unawaited(subscription?.cancel());
    unawaited(controller.close());
  });
  unawaited(() async {
    try {
      await repository.ensureProfile(session, language);
      if (controller.isClosed) return;
      subscription = repository
          .watchProfile(uid)
          .listen(
            controller.add,
            onError: controller.addError,
            onDone: controller.close,
          );
    } catch (error, stack) {
      if (!controller.isClosed) controller.addError(error, stack);
    }
  }());
  return controller.stream;
}, retry: (_, _) => null);

final profileEditorProvider = Provider<ProfileEditor>(
  (ref) => ProfileEditor(
    ref.watch(userProfileRepositoryProvider),
    () => ref.read(firebaseAuthProvider),
  ),
);

class ProfileEditor {
  ProfileEditor(this._repository, this._auth);
  final UserProfileRepository _repository;
  final FirebaseAuth Function() _auth;

  Future<bool> save(
    UserProfile current,
    String username,
    String language,
  ) async {
    final name = normalizeUsername(username);
    if (name == null || !profileLanguages.contains(language)) {
      throw ArgumentError('Invalid username or preferred language');
    }
    await _repository.updateProfile(
      current.uid,
      username: name == current.username ? null : name,
      language: language == current.preferredLanguage ? null : language,
    );
    try {
      await synchronizeName(current.copyWith(username: name));
      return true;
    } on Exception {
      return false;
    }
  }

  Future<void> synchronizeName(UserProfile profile) async {
    final user = _auth().currentUser;
    if (user == null || user.uid != profile.uid || !user.emailVerified) {
      throw FirebaseAuthException(code: 'user-mismatch');
    }
    if (user.displayName != profile.username) {
      await user.updateDisplayName(profile.username);
    }
  }
}
