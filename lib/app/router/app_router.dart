import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/design_system.dart';
import '../../core/widgets/error_screen.dart';
import '../../features/articles/presentation/article_screens.dart';
import '../../features/authentication/application/auth_repository.dart';
import '../../features/authentication/application/auth_controllers.dart';
import '../../features/authentication/presentation/auth_screens.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/couple/presentation/workspace_screen.dart';
import '../../features/finance/presentation/finance_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/account_screens.dart';
import '../../features/shopping/presentation/shopping_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  var signedOut = false;
  ref.listen(authSessionProvider, (previous, next) {
    if (previous?.asData?.value != null &&
        next.asData != null &&
        next.asData!.value == null) {
      signedOut = true;
    } else if (next.asData?.value != null) {
      signedOut = false;
    }
    refresh.value++;
  });
  ref.listen(registrationControllerProvider, (_, _) => refresh.value++);
  final router = GoRouter(
    refreshListenable: refresh,
    redirect: (_, state) {
      final path = state.uri.path;
      final session = ref.read(authSessionProvider);
      if (session.isLoading && !session.hasValue) {
        return path == '/splash' ? null : '/splash';
      }
      if (session.hasError) return path == '/auth-error' ? null : '/auth-error';
      final user = session.asData?.value;
      if (user == null) {
        if (path == '/splash') return signedOut ? '/login' : '/welcome';
        if (const {
          '/welcome',
          '/login',
          '/register',
          '/forgot-password',
          '/language',
        }.contains(path)) {
          return null;
        }
        return '/login';
      }
      if (path == '/register' &&
          ref.read(registrationControllerProvider).isLoading) {
        return null;
      }
      if (!user.verified) {
        return path == '/verify' || path == '/language' ? null : '/verify';
      }
      if (const {
        '/splash',
        '/auth-error',
        '/welcome',
        '/login',
        '/register',
        '/forgot-password',
        '/verify',
      }.contains(path)) {
        return '/authenticated';
      }
      return null;
    },
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
        ('/auth-error', const AuthErrorScreen()),
        ('/authenticated', const AuthenticatedScreen()),
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
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
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
