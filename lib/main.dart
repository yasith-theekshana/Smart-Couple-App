import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/errors/app_error_handling.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureErrorHandling();
  runApp(const ProviderScope(child: SmartCoupleApp()));
}
