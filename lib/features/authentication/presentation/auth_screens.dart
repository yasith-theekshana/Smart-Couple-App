import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/services/demo_state.dart';
import '../../../core/widgets/design_system.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1050), () {
      if (mounted) context.go('/welcome');
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.psychology_outlined,
              color: AppColors.gold,
              size: 53,
            ),
            const SizedBox(height: 30),
            Text.rich(
              const TextSpan(
                children: [
                  TextSpan(
                    text: 'SMART',
                    style: TextStyle(color: AppColors.gold),
                  ),
                  TextSpan(text: 'COUPLE'),
                ],
              ),
              semanticsLabel: 'SMARTCOUPLE',
              textAlign: TextAlign.center,
              style: AppTypography.heading(32).copyWith(letterSpacing: -1.2),
            ),
            const SizedBox(height: 10),
            Container(width: 52, height: 4, color: AppColors.gold),
            const SizedBox(height: 28),
            AppLabel(context.strings.tagline, color: AppColors.muted),
          ],
        ),
      ),
    ),
  );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Scaffold(
      body: AppPage(
        children: [
          const SizedBox(height: 30),
          const Icon(Icons.favorite, color: AppColors.gold, size: 48),
          const SizedBox(height: 14),
          Text(
            'SmartCouple',
            textAlign: TextAlign.center,
            style: AppTypography.heading(39),
          ),
          const SizedBox(height: 9),
          Center(child: AppLabel(s.tagline, color: AppColors.gold)),
          const SizedBox(height: 26),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/couple.jpg',
              height: 170,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 22),
          AppButton(s.login, onPressed: () => context.push('/login')),
          AppButton(
            s.register,
            outlined: true,
            onPressed: () => context.push('/register'),
          ),
          TextButton(onPressed: () => context.go('/'), child: Text(s.openDemo)),
          TextButton(
            onPressed: () => context.push('/language'),
            child: Text(s.language),
          ),
        ],
      ),
    );
  }
}

enum AuthMode { login, register, reset }

class AuthFormScreen extends ConsumerStatefulWidget {
  const AuthFormScreen(this.mode, {super.key});
  final AuthMode mode;

  @override
  ConsumerState<AuthFormScreen> createState() => _AuthFormScreenState();
}

class _AuthFormScreenState extends ConsumerState<AuthFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _resetRequested = false;

  @override
  void dispose() {
    for (final controller in [_name, _email, _password, _confirmation]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    if (widget.mode == AuthMode.reset) {
      setState(() => _resetRequested = true);
      return;
    }
    ref.read(demoSessionProvider.notifier).signIn(_name.text, _email.text);
    context.go(widget.mode == AuthMode.register ? '/verify' : '/workspace');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final title = switch (widget.mode) {
      AuthMode.login => s.login,
      AuthMode.register => s.register,
      AuthMode.reset => s.resetPassword,
    };
    return Scaffold(
      body: AppPage(
        children: [
          AppHeader(title: title),
          AppCard(
            border: AppColors.gold,
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.mode == AuthMode.register) ...[
                    AppTextField(
                      label: s.username,
                      controller: _name,
                      validator: (value) => requiredText(context, value),
                    ),
                    const SizedBox(height: 12),
                  ],
                  AppTextField(
                    label: s.email,
                    controller: _email,
                    keyboard: TextInputType.emailAddress,
                    validator: (value) => emailError(context, value),
                  ),
                  if (widget.mode != AuthMode.reset) ...[
                    const SizedBox(height: 12),
                    AppTextField(
                      label: s.password,
                      controller: _password,
                      obscure: true,
                      validator: (value) =>
                          requiredText(context, value) ??
                          ((value?.length ?? 0) < 8 ? s.shortPassword : null),
                    ),
                  ],
                  if (widget.mode == AuthMode.register) ...[
                    const SizedBox(height: 12),
                    AppTextField(
                      label: s.confirmPassword,
                      controller: _confirmation,
                      obscure: true,
                      validator: (value) =>
                          requiredText(context, value) ??
                          (value != _password.text ? s.passwordMismatch : null),
                    ),
                  ],
                  const SizedBox(height: 16),
                  AppButton(title, onPressed: _submit),
                  if (_resetRequested)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(s.resetSent, textAlign: TextAlign.center),
                    ),
                  if (widget.mode == AuthMode.login)
                    TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: Text(s.forgotPassword),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VerifyEmailScreen extends ConsumerWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.strings;
    final session = ref.watch(demoSessionProvider);
    return Scaffold(
      body: AppPage(
        children: [
          AppHeader(title: s.verifyEmail),
          AppCard(
            border: AppColors.gold,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 36,
                  color: AppColors.gold,
                ),
                const SizedBox(height: 14),
                Text(
                  session.email,
                  textAlign: TextAlign.center,
                  style: AppTypography.heading(20),
                ),
                const SizedBox(height: 12),
                Text(s.verifyHelp, textAlign: TextAlign.center),
                const SizedBox(height: 15),
                AppButton(
                  s.continueLabel,
                  onPressed: () => context.go('/workspace'),
                ),
                TextButton(
                  onPressed: () => ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(s.demoConfirmation))),
                  child: Text(s.verifyAgain),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
