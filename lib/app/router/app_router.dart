import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/error_screen.dart';
import '../../features/home/presentation/home_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())],
    errorBuilder: (context, state) =>
        ErrorScreen(onGoHome: () => context.go('/')),
  );
  ref.onDispose(router.dispose);
  return router;
});
