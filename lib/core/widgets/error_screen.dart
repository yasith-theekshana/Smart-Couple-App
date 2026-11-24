import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../constants/app_constants.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({required this.onGoHome, super.key});

  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.screenPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(strings.pageNotFound, textAlign: TextAlign.center),
                TextButton(onPressed: onGoHome, child: Text(strings.goHome)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
