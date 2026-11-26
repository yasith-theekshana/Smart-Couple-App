import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_couple/features/authentication/application/auth_repository.dart';

const verifiedSession = (
  uid: 'test',
  email: 'user@example.test',
  name: 'Camille',
  verified: true,
);

class TestAuth implements AuthRepository {
  TestAuth(this.session);

  AuthSession? session;
  final _updates = StreamController<AuthSession?>.broadcast();
  int registrations = 0;

  Future<void> close() => _updates.close();

  @override
  Stream<AuthSession?> watchSession() async* {
    yield session;
    yield* _updates.stream;
  }

  @override
  Future<void> register(
    String name,
    String email,
    String password,
    String language,
  ) async {
    registrations++;
    session = (uid: 'test', email: email, name: name, verified: false);
    _updates.add(session);
  }

  @override
  Future<void> login(String email, String password) async {
    throw FirebaseAuthException(code: 'network-request-failed');
  }

  @override
  Future<void> resetPassword(String email, String language) async {}

  @override
  Future<void> sendVerification(String language) async {}

  @override
  Future<bool> refreshVerification() async {
    session = verifiedSession;
    _updates.add(session);
    return true;
  }

  @override
  Future<void> signOut() async {
    session = null;
    _updates.add(null);
  }
}
