import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/design_system.dart';
import '../../core/widgets/error_screen.dart';
import '../../features/articles/presentation/article_screens.dart';
import '../../features/authentication/presentation/auth_screens.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/couple/presentation/workspace_screen.dart';
import '../../features/finance/presentation/finance_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/account_screens.dart';
import '../../features/shopping/presentation/shopping_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => _WorkspaceShell(shell: shell),
        branches: [
          for (final (path, screen) in <(String, Widget)>[
            ('/', const HomeScreen()),
            ('/finance', const FinanceScreen()),
            ('/shopping', const ShoppingScreen()),
            ('/calendar', const CalendarScreen()),
            ('/tasks', const TasksScreen()),
          ])
            StatefulShellBranch(
              routes: [GoRoute(path: path, builder: (_, _) => screen)],
            ),
        ],
      ),
      for (final (path, screen) in <(String, Widget)>[
        ('/splash', const SplashScreen()),
        ('/welcome', const WelcomeScreen()),
        ('/login', const AuthFormScreen(AuthMode.login)),
        ('/register', const AuthFormScreen(AuthMode.register)),
        ('/forgot-password', const AuthFormScreen(AuthMode.reset)),
        ('/verify', const VerifyEmailScreen()),
        ('/workspace', const WorkspaceScreen()),
        ('/workspace/settings', const WorkspaceScreen(settings: true)),
        ('/articles', const ArticleLibrary()),
        ('/profile', const ProfileScreen()),
        ('/settings', const SettingsScreen()),
        ('/language', const LanguageScreen()),
        ('/notifications', const NotificationsScreen()),
      ])
        GoRoute(path: path, builder: (_, _) => screen),
      GoRoute(
        path: '/articles/:index',
        builder: (context, state) {
          final index = int.tryParse(state.pathParameters['index'] ?? '');
          if (index == null || index < 0 || index > 3) {
            return ErrorScreen(onGoHome: () => context.go('/'));
          }
          return ArticleDetail(index: index, fromHome: state.extra == true);
        },
      ),
    ],
    errorBuilder: (context, _) => ErrorScreen(onGoHome: () => context.go('/')),
  );
  ref.onDispose(router.dispose);
  return router;
});

class _WorkspaceShell extends StatelessWidget {
  const _WorkspaceShell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: shell.currentIndex == 0,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && shell.currentIndex != 0) shell.goBranch(0);
    },
    child: Scaffold(
      body: shell,
      bottomNavigationBar: AppBottomNavigation(
        index: shell.currentIndex,
        onSelect: (index) => shell.goBranch(index),
      ),
    ),
  );
}
