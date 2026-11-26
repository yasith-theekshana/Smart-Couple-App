import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/theme/app_theme.dart';
import 'core/errors/app_error_handling.dart';
import 'features/authentication/application/auth_repository.dart';
import 'features/authentication/presentation/auth_screens.dart';
import 'features/profile/application/profile_providers.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureErrorHandling();
  runApp(const _FirebaseStartup());
}

class _FirebaseStartup extends StatefulWidget {
  const _FirebaseStartup();

  @override
  State<_FirebaseStartup> createState() => _FirebaseStartupState();
}

class _FirebaseStartupState extends State<_FirebaseStartup> {
  static const _useEmulators =
      kDebugMode && bool.fromEnvironment('USE_FIREBASE_EMULATORS');

  Future<FirebaseApp> _initialize() async {
    if (!_useEmulators) {
      return Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    final app = await Firebase.initializeApp(
      name: 'smart-couple-local',
      options: const FirebaseOptions(
        apiKey: 'fake-api-key',
        appId: '1:1234567890:android:abc123',
        messagingSenderId: '1234567890',
        projectId: 'demo-smart-couple',
      ),
    );
    await FirebaseAuth.instanceFor(app: app)
        .useAuthEmulator('10.0.2.2', 9099, automaticHostMapping: false);
    FirebaseFirestore.instanceFor(app: app)
        .useFirestoreEmulator('10.0.2.2', 8080, automaticHostMapping: false);
    return app;
  }

  late Future<FirebaseApp> _initialization = _initialize();

  @override
  Widget build(BuildContext context) => FutureBuilder<FirebaseApp>(
    future: _initialization,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          snapshot.hasData) {
        final app = snapshot.requireData;
        return ProviderScope(
          overrides: [
            firebaseAuthProvider.overrideWith(
              (ref) => FirebaseAuth.instanceFor(app: app),
            ),
            firestoreProvider.overrideWith(
              (ref) => FirebaseFirestore.instanceFor(app: app),
            ),
          ],
          child: const SmartCoupleApp(),
        );
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
