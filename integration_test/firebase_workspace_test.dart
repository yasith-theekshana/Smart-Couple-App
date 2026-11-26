import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_couple/app/app.dart';
import 'package:smart_couple/features/authentication/application/auth_repository.dart';
import 'package:smart_couple/features/couple/data/couple_workspace_repository.dart';
import 'package:smart_couple/features/profile/application/profile_providers.dart';
import 'package:smart_couple/features/profile/data/user_profile_repository.dart';

import 'firebase_profile_test.dart' show verifyEmulatedProfileAccount;

// Keep app data across invocations with --no-uninstall for the restore phase.
const _phase = String.fromEnvironment('WORKSPACE_TEST_PHASE');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Firestore workspace creation, settings, concurrency and restart',
    (tester) async {
      final app = await Firebase.initializeApp(
        name: 'smart-couple-workspace-test',
        options: const FirebaseOptions(
          apiKey: 'fake-api-key',
          appId: '1:1234567890:android:abc123',
          messagingSenderId: '1234567890',
          projectId: 'demo-smart-couple',
        ),
      );
      final auth = FirebaseAuth.instanceFor(app: app);
      await auth.useAuthEmulator('10.0.2.2', 9099, automaticHostMapping: false);
      final firestore = FirebaseFirestore.instanceFor(app: app)
        ..useFirestoreEmulator('10.0.2.2', 8080, automaticHostMapping: false);
      final accounts = FirebaseAuthRepository(auth);
      final profiles = FirestoreUserProfileRepository(firestore);
      final workspaces = FirestoreCoupleWorkspaceRepository(firestore);

      Future<void> mountApp() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              firebaseAuthProvider.overrideWithValue(auth),
              firestoreProvider.overrideWithValue(firestore),
            ],
            child: const SmartCoupleApp(),
          ),
        );
        await tester.pumpAndSettle();
      }

      if (_phase == 'restore') {
        final session = (await accounts.watchSession().first)!;
        final profile = (await profiles.getProfile(session.uid))!;
        final workspace = (await workspaces.getWorkspace(
          profile.coupleId!,
          session.uid,
        ))!;
        expect(workspace.name, 'Our Family');
        expect(workspace.currency, 'USD');
        expect(workspace.memberIds, [session.uid]);
        await mountApp();
        expect(find.text('Our Family'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        await accounts.signOut();
        return;
      }

      await accounts.signOut();
      if (_phase != 'seed') addTearDown(accounts.signOut);
      final suffix = DateTime.now().microsecondsSinceEpoch;
      final email = 'workspace-$suffix@example.test';
      const password = 'workspace-emulator-password';
      await accounts.register('Camille', email, password, 'en');
      await verifyEmulatedProfileAccount(auth, accounts, email);
      final session = (await accounts.watchSession().first)!;
      await expectLater(
        workspaces.createWorkspace(session, 'Our Home', 'LKR'),
        throwsStateError,
      );
      await profiles.ensureProfile(session, 'en');
      await expectLater(
        workspaces.createWorkspace(session, '  ', 'LKR'),
        throwsArgumentError,
      );
      await expectLater(
        workspaces.createWorkspace(session, 'Our Home', 'XYZ'),
        throwsArgumentError,
      );
      expect((await profiles.getProfile(session.uid))?.coupleId, isNull);

      await mountApp();
      await tester.enterText(find.byType(TextFormField).first, 'Our Home');
      await tester.tap(find.text('CREATE WORKSPACE'));
      await tester.pumpAndSettle();
      expect(find.text('Our Home'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
      final linked = (await profiles.getProfile(session.uid))!;
      final initial = (await workspaces.getWorkspace(
        linked.coupleId!,
        session.uid,
      ))!;
      expect(initial.currency, 'LKR');
      expect(initial.memberIds, [session.uid]);
      expect(initial.createdAt, isNotNull);
      await workspaces.updateSettings(
        initial,
        session.uid,
        'Our Family',
        'USD',
      );
      await tester.pumpAndSettle();
      expect(find.text('Our Family'), findsOneWidget);
      final update = (await workspaces.getWorkspace(initial.id, session.uid))!;
      expect(update.createdAt, initial.createdAt);
      expect(update.updatedAt!.isAfter(initial.updatedAt!), isTrue);
      expect(
        await workspaces.createWorkspace(session, 'Duplicate', 'EUR'),
        initial.id,
      );

      await firestore.disableNetwork();
      try {
        await expectLater(
          workspaces.getWorkspace(initial.id, session.uid),
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

      await tester.pumpWidget(const SizedBox.shrink());
      await accounts.signOut();
      final otherEmail = 'workspace-other-$suffix@example.test';
      await accounts.register('Morgan', otherEmail, password, 'en');
      await verifyEmulatedProfileAccount(auth, accounts, otherEmail);
      final other = (await accounts.watchSession().first)!;
      await profiles.ensureProfile(other, 'en');
      await expectLater(
        workspaces.getWorkspace(initial.id, other.uid),
        throwsA(
          isA<FirebaseException>().having(
            (error) => error.code,
            'code',
            'permission-denied',
          ),
        ),
      );
      final ids = await Future.wait([
        workspaces.createWorkspace(other, 'Concurrent A', 'LKR'),
        workspaces.createWorkspace(other, 'Concurrent B', 'GBP'),
      ]);
      expect(ids.toSet(), hasLength(1));
      expect((await profiles.getProfile(other.uid))?.coupleId, ids.first);
      await accounts.signOut();
      await accounts.login(email, password);
      expect((await profiles.getProfile(session.uid))?.coupleId, initial.id);
    },
  );
}
