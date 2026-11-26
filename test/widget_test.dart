import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_couple/app/app.dart';
import 'package:smart_couple/app/router/app_router.dart';
import 'package:smart_couple/core/services/demo_state.dart';
import 'package:smart_couple/features/authentication/application/auth_repository.dart';

import 'package:smart_couple/features/profile/application/profile_providers.dart';
import 'package:smart_couple/features/profile/data/user_profile.dart';

import 'test_auth.dart';
import 'test_profiles.dart';

Future<ProviderContainer> startApp(
  WidgetTester tester, {
  String path = '/',
  TestAuth? auth,
  TestProfiles? profiles,
  bool enableDemoRoutes = true,
}) async {
  final repository = auth ?? TestAuth(verifiedSession);
  final profileRepository = profiles ?? TestProfiles();
  addTearDown(repository.close);
  addTearDown(profileRepository.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        userProfileRepositoryProvider.overrideWithValue(profileRepository),
        profileEditorProvider.overrideWithValue(_TestEditor(profileRepository)),
        if (enableDemoRoutes)
          appRouterProvider.overrideWith(
            (ref) => createAppRouter(ref, enableDemoRoutes: true),
          ),
      ],
      child: const SmartCoupleApp(),
    ),
  );
  await tester.pump();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(SmartCoupleApp)),
    listen: false,
  );
  container.read(appRouterProvider).go(path);
  await tester.pumpAndSettle();
  return container;
}

Future<void> go(
  WidgetTester tester,
  ProviderContainer container,
  String path,
) async {
  container.read(appRouterProvider).go(path);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Verified users edit their profile while demo routes stay closed',
    (tester) async {
      final profiles = TestProfiles();
      final container = await startApp(
        tester,
        path: '/finance',
        profiles: profiles,
        enableDemoRoutes: false,
      );
      expect(find.text('Camille'), findsOneWidget);
      expect(find.text('Finances'), findsNothing);
      await tester.tap(find.text('EDIT PROFILE'));
      await tester.pumpAndSettle();
      final username = find.byType(TextFormField);
      await tester.enterText(username, '   ');
      final save = find.text('SAVE CHANGES');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(
        find.text('Enter a username from 1 to 50 characters.'),
        findsOneWidget,
      );
      await tester.enterText(username, '  Camille Roy  ');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('Camille Roy'), findsOneWidget);
      await container
          .read(userProfileRepositoryProvider)
          .updateProfile('test', language: 'fr');
      await tester.pumpAndSettle();
      expect(find.text('MODIFIER LE PROFIL'), findsOneWidget);
    },
  );

  testWidgets('Profile permission and network errors can be retried', (
    tester,
  ) async {
    final profiles = TestProfiles()
      ..loadError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    await startApp(
      tester,
      path: '/profile',
      profiles: profiles,
      enableDemoRoutes: false,
    );
    expect(
      find.text('Firestore denied access to your profile.'),
      findsOneWidget,
    );
    expect(find.text('SIGN OUT'), findsOneWidget);
    profiles.loadError = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
    );
    await tester.tap(find.text('TRY AGAIN'));
    await tester.pumpAndSettle();
    expect(
      find.text('Check your internet connection and try again.'),
      findsOneWidget,
    );
    expect(profiles.profiles, isEmpty);
    profiles.loadError = null;
    await tester.tap(find.text('TRY AGAIN'));
    await tester.pumpAndSettle();
    expect(find.text('Camille'), findsOneWidget);
  });

  testWidgets(
    'Account switch and logout dispose the previous profile listener',
    (tester) async {
      final profiles = TestProfiles();
      final auth = TestAuth(verifiedSession);
      await startApp(
        tester,
        path: '/profile',
        auth: auth,
        profiles: profiles,
        enableDemoRoutes: false,
      );
      expect(profiles.activeListeners, {'test'});
      auth.setSession((
        uid: 'other',
        email: 'other@example.test',
        name: 'Morgan',
        verified: true,
        accountCreatedAt: null,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Camille'), findsNothing);
      expect(find.text('Morgan'), findsOneWidget);
      expect(profiles.activeListeners, {'other'});
      await auth.signOut();
      await tester.pumpAndSettle();
      expect(profiles.activeListeners, isEmpty);
      expect(find.byType(TextFormField), findsNWidgets(2));
    },
  );

  testWidgets('Signed-out users see welcome and protected links go to login', (
    tester,
  ) async {
    final container = await startApp(
      tester,
      path: '/welcome',
      auth: TestAuth(null),
    );
    expect(find.text('SmartCouple'), findsOneWidget);
    expect(find.text('Open demo workspace'), findsNothing);
    await go(tester, container, '/finance');
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Finances'), findsNothing);
  });

  testWidgets('Login displays a localized network failure', (tester) async {
    final container = await startApp(
      tester,
      path: '/login',
      auth: TestAuth(null),
    );
    container.read(localeProvider.notifier).select(const Locale('fr'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'user@example.test');
    await tester.enterText(fields.at(1), 'password');
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
    expect(
      find.text('Vérifiez votre connexion Internet et réessayez.'),
      findsOneWidget,
    );
  });

  testWidgets('Unverified session is guarded and logout returns to login', (
    tester,
  ) async {
    final auth = TestAuth((
      uid: 'test',
      email: 'user@example.test',
      name: null,
      verified: false,
      accountCreatedAt: null,
    ));
    final container = await startApp(tester, path: '/tasks', auth: auth);
    expect(find.text('Verify email'), findsOneWidget);
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
    expect(find.text('Your email is verified'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'SIGN OUT'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    await go(tester, container, '/authenticated');
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('System back returns from a secondary tab to Home', (
    tester,
  ) async {
    await startApp(tester, path: '/finance');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Florian & Sophie'), findsOneWidget);
  });

  testWidgets('Expense form validates and saves a new transaction', (
    tester,
  ) async {
    await startApp(tester, path: '/finance');
    await tester.tap(find.text('EXPENSES'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();
    expect(find.text('This field is required.'), findsWidgets);
    await tester.enterText(find.byType(TextFormField).at(0), 'Train fare');
    await tester.enterText(find.byType(TextFormField).at(1), '18.75');
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();
    expect(find.text('Train fare'), findsOneWidget);
  });

  testWidgets('Calendar event can be created and opened', (tester) async {
    await startApp(tester, path: '/calendar');
    await tester.tap(find.byTooltip('New event'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Dinner out');
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dinner out'));
    await tester.pumpAndSettle();
    expect(find.text('Event details'), findsOneWidget);
  });

  testWidgets('Bottom navigation opens the five primary screens', (
    tester,
  ) async {
    await startApp(tester);
    for (final (label, heading) in [
      ('Finances', 'Finances'),
      ('Shopping', 'Shopping'),
      ('Agenda', 'Calendar'),
      ('Household', 'Household'),
      ('Home', 'Florian & Sophie'),
    ]) {
      await tester.tap(find.byTooltip(label));
      await tester.pumpAndSettle();
      expect(find.text(heading), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'French locale switches at runtime and translates unknown routes',
    (tester) async {
      final container = await startApp(tester, path: '/language');
      await tester.tap(find.text('Français (FR)'));
      await container
          .read(userProfileRepositoryProvider)
          .updateProfile('test', language: 'fr');
      await tester.pumpAndSettle();
      expect(find.text('Langue'), findsOneWidget);
      await go(tester, container, '/missing');
      expect(find.text('Page introuvable'), findsOneWidget);
      await tester.tap(find.text('Retour à l’accueil'));
      await tester.pumpAndSettle();
      expect(find.text('ACCUEIL'), findsOneWidget);
    },
  );

  testWidgets(
    'Registration validates confirmation and starts Firebase verification through the repository',
    (tester) async {
      final auth = TestAuth(null);
      await startApp(tester, path: '/register', auth: auth);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Camille');
      await tester.enterText(fields.at(1), 'camille@example.test');
      await tester.enterText(fields.at(2), 'samplePassword');
      await tester.enterText(fields.at(3), 'different');
      await tester.ensureVisible(find.text('CREATE ACCOUNT'));
      await tester.tap(find.text('CREATE ACCOUNT'));
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(auth.registrations, 0);
      await tester.enterText(fields.at(3), 'samplePassword');
      await tester.ensureVisible(find.text('CREATE ACCOUNT'));
      await tester.tap(find.text('CREATE ACCOUNT'));
      await tester.pumpAndSettle();
      expect(find.text('Verify email'), findsOneWidget);
      expect(find.text('camille@example.test'), findsOneWidget);
      expect(find.textContaining('Resend in'), findsOneWidget);
    },
  );

  testWidgets('Workspace can send and accept a demo email invitation', (
    tester,
  ) async {
    final container = await startApp(tester, path: '/workspace');
    await tester.enterText(find.byType(TextFormField).first, 'Our place');
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'partner@example.test',
    );
    await tester.tap(find.text('SEND INVITATION'));
    await tester.pumpAndSettle();
    expect(find.text('Pending invitation'), findsOneWidget);
    await tester.tap(find.text('PREVIEW INCOMING INVITATION'));
    await tester.pumpAndSettle();
    expect(find.text('Incoming invitation'), findsOneWidget);
    await tester.tap(find.text('ACCEPT'));
    await tester.pumpAndSettle();
    expect(find.text('Couple connected'), findsOneWidget);
    expect(
      container.read(demoSessionProvider).invitation,
      InvitationStatus.connected,
    );
  });

  testWidgets('Shopping adds items and updates the pending count', (
    tester,
  ) async {
    await startApp(tester, path: '/shopping');
    await tester.enterText(find.byType(TextFormField).first, 'Tea');
    await tester.tap(find.byTooltip('Add'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Tea'),
      130,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
    expect(find.text('Tea'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('All destinations render in both languages at a narrow width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(330, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = await startApp(tester);
    for (final language in ['en', 'fr']) {
      await container
          .read(userProfileRepositoryProvider)
          .updateProfile('test', language: language);
      for (final path in [
        '/',
        '/finance',
        '/shopping',
        '/calendar',
        '/tasks',
        '/authenticated',
        '/workspace',
        '/workspace/settings',
        '/articles',
        '/articles/0',
        '/profile',
        '/settings',
        '/language',
        '/notifications',
      ]) {
        await go(tester, container, path);
        expect(tester.takeException(), isNull, reason: '$language $path');
      }
    }
  });
  testWidgets('Account sheet opens settings over the tab shell', (
    tester,
  ) async {
    await startApp(tester);
    await tester.tap(find.byTooltip('My profile'));
    await tester.pumpAndSettle();
    final settings = find.text('SETTINGS');
    await tester.ensureVisible(settings);
    await tester.tap(settings);
    await tester.pumpAndSettle();
    expect(find.text('Workspace settings'), findsOneWidget);
  });
}

class _TestEditor extends ProfileEditor {
  _TestEditor(TestProfiles profiles)
    : super(profiles, () => throw StateError('Unexpected Firebase call'));

  @override
  Future<void> synchronizeName(UserProfile profile) async {}
}
