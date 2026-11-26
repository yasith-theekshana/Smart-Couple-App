import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef AuthSession = ({
  String uid,
  String email,
  String? name,
  bool verified,
  DateTime? accountCreatedAt,
});

class RegistrationSetupFailure implements Exception {
  const RegistrationSetupFailure(this.uid);

  final String uid;
}

abstract interface class AuthRepository {
  Stream<AuthSession?> watchSession();
  Future<void> register(
    String name,
    String email,
    String password,
    String language,
  );
  Future<void> login(String email, String password);
  Future<void> resetPassword(String email, String language);
  Future<void> sendVerification(String language);
  Future<bool> refreshVerification();
  Future<void> signOut();
}

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(ref.watch(firebaseAuthProvider)),
);
final authSessionProvider = StreamProvider<AuthSession?>(
  (ref) => ref.watch(authRepositoryProvider).watchSession(),
);

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;
  ({String uid, String name})? _pendingName;

  @override
  Stream<AuthSession?> watchSession() =>
      _auth.userChanges().asyncMap((user) async {
        if (user == null) return null;
        final verified =
            user.emailVerified &&
            (await user.getIdTokenResult()).claims?['email_verified'] == true;
        return (
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName,
          verified: verified,
          accountCreatedAt: user.metadata.creationTime,
        );
      });

  User get _user =>
      _auth.currentUser ??
      (throw FirebaseAuthException(code: 'no-current-user'));

  Future<void> _saveName(User user) async {
    final pending = _pendingName;
    if (pending == null || pending.uid != user.uid) return;
    await user.updateDisplayName(pending.name);
    _pendingName = null;
  }

  @override
  Future<void> register(
    String name,
    String email,
    String password,
    String language,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    _pendingName = (uid: user.uid, name: name);
    try {
      try {
        await _saveName(user);
      } finally {
        await sendVerification(language);
      }
    } catch (_, stack) {
      Error.throwWithStackTrace(RegistrationSetupFailure(user.uid), stack);
    }
  }

  @override
  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> resetPassword(String email, String language) async {
    try {
      await _auth.setLanguageCode(language);
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      if (!const {'user-not-found', 'user-disabled'}.contains(error.code)) {
        rethrow;
      }
    }
  }

  @override
  Future<void> sendVerification(String language) async {
    final user = _user;
    await _auth.setLanguageCode(language);
    await user.sendEmailVerification();
  }

  @override
  Future<bool> refreshVerification() async {
    final original = _user;
    try {
      await _saveName(original);
      await original.reload();
      final user = _auth.currentUser;
      if (user == null || user.uid != original.uid || !user.emailVerified) {
        return false;
      }
      final token = await user.getIdTokenResult(true);
      return token.claims?['email_verified'] == true;
    } on FirebaseAuthException catch (error) {
      if (const {
            'user-disabled',
            'user-not-found',
            'invalid-user-token',
            'user-token-expired',
          }.contains(error.code) &&
          _auth.currentUser?.uid == original.uid) {
        await signOut();
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
