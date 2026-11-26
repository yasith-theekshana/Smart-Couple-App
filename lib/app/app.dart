import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/services/demo_state.dart';
import '../features/profile/application/profile_providers.dart';
import '../l10n/app_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class SmartCoupleApp extends ConsumerWidget {
  const SmartCoupleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(activeProfileProvider);
    final profile = profileState.isLoading ? null : profileState.asData?.value;
    return MaterialApp.router(
      title: AppConstants.name,
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(appRouterProvider),
      theme: AppTheme.light,
      locale: profile == null
          ? ref.watch(localeProvider)
          : Locale(profile.preferredLanguage),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
