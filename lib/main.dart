import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/theme/app_theme.dart';
import 'core/errors/app_error_handling.dart';
import 'features/authentication/presentation/auth_screens.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureErrorHandling();
  runApp(const ProviderScope(child: _FirebaseStartup()));
}

class _FirebaseStartup extends StatefulWidget {
  const _FirebaseStartup();

  @override
  State<_FirebaseStartup> createState() => _FirebaseStartupState();
}

class _FirebaseStartupState extends State<_FirebaseStartup> {
  Future<FirebaseApp> _initialize() =>
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  late Future<FirebaseApp> _initialization = _initialize();

  @override
  Widget build(BuildContext context) => FutureBuilder<FirebaseApp>(
    future: _initialization,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          snapshot.hasData) {
        return const SmartCoupleApp();
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SplashScreen(
          onRetry: snapshot.hasError
              ? () => setState(() => _initialization = _initialize())
              : null,
        ),
      );
    },
  );
}
