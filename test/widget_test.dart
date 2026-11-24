import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_couple/app/app.dart';
import 'package:smart_couple/app/router/app_router.dart';
import 'package:smart_couple/core/services/demo_state.dart';

Future<ProviderContainer> startApp(
  WidgetTester tester, {
  String path = '/',
}) async {
  await tester.pumpWidget(const ProviderScope(child: SmartCoupleApp()));
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
  testWidgets('Splash advances to welcome and opens the demo', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmartCoupleApp()));
    await tester.pump();
    expect(find.text('SMARTCOUPLE'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open demo workspace'));
    await tester.pumpAndSettle();
    expect(find.text('Florian & Sophie'), findsOneWidget);
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
    'Registration validates confirmation and hands off to demo verification',
    (tester) async {
      await startApp(tester, path: '/register');
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Camille');
      await tester.enterText(fields.at(1), 'camille@example.test');
      await tester.enterText(fields.at(2), 'samplePassword');
      await tester.enterText(fields.at(3), 'different');
      await tester.ensureVisible(find.text('CREATE ACCOUNT'));
      await tester.tap(find.text('CREATE ACCOUNT'));
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match.'), findsOneWidget);
      await tester.enterText(fields.at(3), 'samplePassword');
      await tester.ensureVisible(find.text('CREATE ACCOUNT'));
      await tester.tap(find.text('CREATE ACCOUNT'));
      await tester.pumpAndSettle();
      expect(find.text('Verify email'), findsOneWidget);
      expect(find.text('camille@example.test'), findsOneWidget);
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
      container.read(localeProvider.notifier).select(Locale(language));
      for (final path in [
        '/',
        '/finance',
        '/shopping',
        '/calendar',
        '/tasks',
        '/welcome',
        '/login',
        '/register',
        '/forgot-password',
        '/verify',
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
