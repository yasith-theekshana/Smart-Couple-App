import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_couple/features/authentication/application/auth_repository.dart';

const _host = '10.0.2.2';
const _port = 9099;
const _project = 'demo-smart-couple';
// Run seed and restore in separate invocations with --no-uninstall so Android
// retains Firebase's persisted session between app processes.
const _persistencePhase = String.fromEnvironment('AUTH_TEST_PERSISTENCE');

Future<List<Map<String, dynamic>>> _codes(String email, String type) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  try {
    final request = await client.getUrl(
      Uri.http('$_host:$_port', '/emulator/v1/projects/$_project/oobCodes'),
    );
    final response = await request.close();
    expect(response.statusCode, HttpStatus.ok);
    final body =
        jsonDecode(await response.transform(utf8.decoder).join()) as Map;
    return (body['oobCodes'] as List)
        .cast<Map<String, dynamic>>()
        .where((item) => item['email'] == email && item['requestType'] == type)
        .toList();
  } finally {
    client.close(force: true);
  }
}

Matcher _authCode(Set<String> codes) => isA<FirebaseAuthException>().having(
  (error) => error.code,
  'code',
  isIn(codes),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Firebase Auth emulator registration, verification, reset and sessions',
    (tester) async {
      final app = await Firebase.initializeApp(
        name: 'smart-couple-auth-test',
        options: const FirebaseOptions(
          apiKey: 'fake-api-key',
          appId: '1:1234567890:android:abc123',
          messagingSenderId: '1234567890',
          projectId: _project,
        ),
      );
      final auth = FirebaseAuth.instanceFor(app: app);
      await auth.useAuthEmulator(_host, _port, automaticHostMapping: false);
      final repository = FirebaseAuthRepository(auth);
      if (_persistencePhase == 'restore') {
        final restored = await repository.watchSession().first;
        expect(restored?.email, startsWith('step04+'));
        expect(restored?.name, 'Camille');
        expect(restored?.verified, true);
        await repository.signOut();
        expect(await repository.watchSession().first, isNull);
        return;
      }
      final email =
          'step04+${DateTime.now().microsecondsSinceEpoch}@example.test';
      const initialPassword = 'initial-test-password';
      const newPassword = 'reset-test-password';
      await repository.signOut();
      if (_persistencePhase != 'seed') addTearDown(repository.signOut);

      await repository.register('Camille', email, initialPassword, 'en');
      final registered = await repository.watchSession().first;
      expect(registered?.email, email);
      expect(registered?.name, 'Camille');
      expect(registered?.verified, false);
      expect(await repository.refreshVerification(), false);

      final firstVerification = await _codes(email, 'VERIFY_EMAIL');
      expect(firstVerification, hasLength(1));
      await repository.sendVerification('fr');
      final allVerification = await _codes(email, 'VERIFY_EMAIL');
      final resent = allVerification.singleWhere(
        (action) => action['oobCode'] != firstVerification.single['oobCode'],
      );
      await auth.applyActionCode(resent['oobCode'] as String);
      expect(await repository.refreshVerification(), true);
      expect((await repository.watchSession().first)?.verified, true);

      await repository.signOut();
      expect(await repository.watchSession().first, isNull);
      await expectLater(
        repository.register('Camille', email, initialPassword, 'en'),
        throwsA(_authCode({'email-already-in-use'})),
      );
      await expectLater(
        repository.login(email, 'wrong-password'),
        throwsA(
          _authCode({
            'wrong-password',
            'invalid-credential',
            'invalid-login-credentials',
          }),
        ),
      );
      await repository.login(email, initialPassword);
      final restored = await FirebaseAuthRepository(
        FirebaseAuth.instanceFor(app: app),
      ).watchSession().first;
      expect(restored?.uid, registered?.uid);
      expect(restored?.verified, true);

      await repository.signOut();
      await repository.resetPassword('absent-$email', 'en');
      await repository.resetPassword(email, 'en');
      final reset = (await _codes(email, 'PASSWORD_RESET')).single;
      await auth.confirmPasswordReset(
        code: reset['oobCode'] as String,
        newPassword: newPassword,
      );
      await expectLater(
        repository.login(email, initialPassword),
        throwsA(
          _authCode({
            'wrong-password',
            'invalid-credential',
            'invalid-login-credentials',
          }),
        ),
      );
      await repository.login(email, newPassword);
      expect((await repository.watchSession().first)?.verified, true);
      if (_persistencePhase == 'seed') return;
      await repository.signOut();
      expect(await repository.watchSession().first, isNull);
    },
  );
}
