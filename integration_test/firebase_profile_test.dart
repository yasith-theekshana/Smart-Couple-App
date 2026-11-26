import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_couple/features/authentication/application/auth_repository.dart';
import 'package:smart_couple/features/profile/application/profile_providers.dart';
import 'package:smart_couple/features/profile/data/user_profile_repository.dart';

const _project = 'demo-smart-couple';
const _host = '10.0.2.2';
const _password = 'emulator-test-password';
const _phase = String.fromEnvironment('PROFILE_TEST_PHASE');

Future<void> verifyEmulatedProfileAccount(
  FirebaseAuth auth,
  FirebaseAuthRepository repository,
  String email,
) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  try {
    final request = await client.getUrl(
      Uri.http('$_host:9099', '/emulator/v1/projects/$_project/oobCodes'),
    );
    final response = await request.close();
    expect(response.statusCode, HttpStatus.ok);
    final result =
        jsonDecode(await response.transform(utf8.decoder).join()) as Map;
    final codes = (result['oobCodes'] as List).cast<Map<String, dynamic>>();
    final code = codes.singleWhere(
      (item) => item['email'] == email && item['requestType'] == 'VERIFY_EMAIL',
    );
    await auth.applyActionCode(code['oobCode'] as String);
    expect(await repository.refreshVerification(), isTrue);
  } finally {
    client.close(force: true);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Firestore profile creation, edits, isolation and persistence', (
    tester,
  ) async {
    // This named app isolates emulator credentials from the production app.
    final app = await Firebase.initializeApp(
      name: 'smart-couple-local',
      options: const FirebaseOptions(
        apiKey: 'fake-api-key',
        appId: '1:1234567890:android:abc123',
        messagingSenderId: '1234567890',
        projectId: _project,
      ),
    );
    final auth = FirebaseAuth.instanceFor(app: app);
    await auth.useAuthEmulator(_host, 9099, automaticHostMapping: false);
    final firestore = FirebaseFirestore.instanceFor(app: app)
      ..useFirestoreEmulator(_host, 8080, automaticHostMapping: false);
    final accounts = FirebaseAuthRepository(auth);
    final profiles = FirestoreUserProfileRepository(firestore);

    if (_phase == 'restore') {
      final user = (await accounts.watchSession().first)!;
      expect(user.verified, isTrue);
      await profiles.ensureProfile(user, 'en');
      final restored = await profiles.getProfile(user.uid);
      expect(restored?.username, 'Camille Roy');
      expect(restored?.preferredLanguage, 'fr');
      expect(restored?.createdAt, isNotNull);
      return;
    }
    if (_phase != 'seed') addTearDown(accounts.signOut);
    await accounts.signOut();
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final email = 'profile-$suffix@example.test';
    await accounts.register('Camille', email, _password, 'en');
    await verifyEmulatedProfileAccount(auth, accounts, email);

    // Simulate an existing Auth account signing in with no Firestore document.
    await accounts.signOut();
    await accounts.login(email, _password);
    final user = (await accounts.watchSession().first)!;
    expect(user.verified, isTrue);
    expect(await profiles.exists(user.uid), isFalse);
    await Future.wait([
      profiles.ensureProfile(user, 'fr'),
      profiles.ensureProfile(user, 'fr'),
    ]);
    final initial = (await profiles.getProfile(user.uid))!;
    expect(initial.uid, user.uid);
    expect(initial.email, email);
    expect(initial.username, 'Camille');
    expect(initial.preferredLanguage, 'fr');
    expect(initial.coupleId, isNull);
    expect(initial.createdAt, isNotNull);
    expect(initial.updatedAt, initial.createdAt);

    final editor = ProfileEditor(profiles, () => auth);
    final nextProfile = profiles
        .watchProfile(user.uid)
        .firstWhere((profile) => profile?.username == 'Camille Roy');
    expect(await editor.save(initial, '  Camille Roy  ', 'en'), isTrue);
    expect((await nextProfile)?.preferredLanguage, 'en');
    expect(auth.currentUser?.displayName, 'Camille Roy');
    await profiles.updateProfile(user.uid, language: 'fr');

    await firestore.disableNetwork();
    try {
      await expectLater(
        profiles.getProfile(user.uid),
        throwsA(
          isA<FirebaseException>().having(
            (error) => error.code,
            'code',
            'unavailable',
          ),
        ),
      );
    } finally {
      await firestore.enableNetwork();
    }

    await accounts.signOut();
    await expectLater(
      profiles.getProfile(user.uid),
      throwsA(
        isA<FirebaseException>().having(
          (error) => error.code,
          'code',
          'permission-denied',
        ),
      ),
    );
    final otherEmail = 'other-$suffix@example.test';
    await accounts.register('Morgan', otherEmail, _password, 'en');
    await verifyEmulatedProfileAccount(auth, accounts, otherEmail);
    final other = (await accounts.watchSession().first)!;
    await profiles.ensureProfile(other, 'en');
    expect((await profiles.getProfile(other.uid))?.username, 'Morgan');
    await expectLater(
      profiles.getProfile(user.uid),
      throwsA(
        isA<FirebaseException>().having(
          (error) => error.code,
          'code',
          'permission-denied',
        ),
      ),
    );

    await accounts.signOut();
    await accounts.login(email, _password);
    final signedIn = (await accounts.watchSession().first)!;
    await profiles.ensureProfile(signedIn, 'en');
    final afterLogin = await profiles.getProfile(user.uid);
    expect(afterLogin?.username, 'Camille Roy');
    expect(afterLogin?.preferredLanguage, 'fr');
    expect(afterLogin?.coupleId, initial.coupleId);
    expect(afterLogin?.createdAt, initial.createdAt);
    expect(afterLogin!.updatedAt!.isAfter(initial.updatedAt!), isTrue);
  });
}
