import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_couple/app/app.dart';
import 'package:smart_couple/app/router/app_router.dart';

void main() {
  testWidgets('Shows SmartCouple on the home route', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmartCoupleApp()));
    await tester.pumpAndSettle();

    expect(find.text('SmartCouple'), findsOneWidget);
  });

  testWidgets('Localizes unknown routes and returns home in French', (
    tester,
  ) async {
    final dispatcher = tester.binding.platformDispatcher;
    dispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(dispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const ProviderScope(child: SmartCoupleApp()));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SmartCoupleApp)),
      listen: false,
    );
    container.read(appRouterProvider).go('/missing');
    await tester.pumpAndSettle();

    expect(find.text('Page introuvable'), findsOneWidget);
    await tester.tap(find.text('Retour à l’accueil'));
    await tester.pumpAndSettle();

    expect(find.text('SmartCouple'), findsOneWidget);
  });
}
