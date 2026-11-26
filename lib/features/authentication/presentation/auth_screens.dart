import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../application/auth_controllers.dart';
import '../application/auth_repository.dart';
import '../../../core/widgets/design_system.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({this.onRetry, super.key});
  final VoidCallback? onRetry;

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
            const SizedBox(height: 20),
            if (onRetry == null)
              const AppLoadingIndicator()
            else ...[
              Text(
                context.strings.authStartupError,
                textAlign: TextAlign.center,
              ),
              AppButton(context.strings.authRetry, onPressed: onRetry),
            ],
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
  bool _busy = false;
  bool _showPassword = false;
  bool _showConfirmation = false;
  Object? _error;

  @override
  void dispose() {
    for (final controller in [_name, _email, _password, _confirmation]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    final language = Localizations.localeOf(context).languageCode;
    setState(() {
      _busy = true;
      _error = null;
      _resetRequested = false;
    });
    try {
      switch (widget.mode) {
        case AuthMode.register:
          await ref
              .read(registrationControllerProvider.notifier)
              .submit(_name.text.trim(), email, _password.text, language);
        case AuthMode.login:
          await ref.read(loginControllerProvider).submit(email, _password.text);
        case AuthMode.reset:
          await ref
              .read(passwordResetControllerProvider)
              .submit(email, language);
          if (mounted) setState(() => _resetRequested = true);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _visibility(bool visible, VoidCallback toggle) => IconButton(
    tooltip: visible
        ? context.strings.authHidePassword
        : context.strings.authShowPassword,
    onPressed: _busy ? null : toggle,
    icon: Icon(
      visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
    ),
  );

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
          AppHeader(
            title: title,
            onBack: () => context.go(
              widget.mode == AuthMode.reset ? '/login' : '/welcome',
            ),
          ),
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
                      enabled: !_busy,
                      validator: (value) => requiredText(context, value),
                    ),
                    const SizedBox(height: 12),
                  ],
                  AppTextField(
                    label: s.email,
                    controller: _email,
                    enabled: !_busy,
                    keyboard: TextInputType.emailAddress,
                    validator: (value) => emailError(context, value),
                  ),
                  if (widget.mode != AuthMode.reset) ...[
                    const SizedBox(height: 12),
                    AppTextField(
                      label: s.password,
                      controller: _password,
                      enabled: !_busy,
                      obscure: !_showPassword,
                      suffixIcon: _visibility(
                        _showPassword,
                        () => setState(() => _showPassword = !_showPassword),
                      ),
                      validator: (value) => (value?.isEmpty ?? true)
                          ? requiredText(context, null)
                          : widget.mode == AuthMode.register &&
                                value!.length < 8
                          ? s.shortPassword
                          : null,
                    ),
                  ],
                  if (widget.mode == AuthMode.register) ...[
                    const SizedBox(height: 12),
                    AppTextField(
                      label: s.confirmPassword,
                      controller: _confirmation,
                      enabled: !_busy,
                      obscure: !_showConfirmation,
                      suffixIcon: _visibility(
                        _showConfirmation,
                        () => setState(
                          () => _showConfirmation = !_showConfirmation,
                        ),
                      ),
                      validator: (value) =>
                          requiredText(context, value) ??
                          (value != _password.text ? s.passwordMismatch : null),
                    ),
                  ],
                  const SizedBox(height: 16),
                  AppButton(title, onPressed: _busy ? null : _submit),
                  if (_busy) const AppLoadingIndicator(),
                  if (_error != null)
                    _AuthMessage(_authError(s, _error!), isError: true),
                  if (_resetRequested)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(s.resetSent, textAlign: TextAlign.center),
                    ),
                  if (widget.mode == AuthMode.reset)
                    TextButton(
                      onPressed: _busy ? null : () => context.go('/login'),
                      child: Text(s.login),
                    ),
                  if (widget.mode == AuthMode.login)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => context.push('/forgot-password'),
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

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  late final AppLifecycleListener _lifecycle;
  Timer? _timer;
  bool _busy = false;
  String Function(AppLocalizations)? _message;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => _check(automatic: true));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } catch (error) {
      _message = (s) => _authError(s, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check({bool automatic = false}) => _perform(() async {
    final verified = await ref.read(verificationControllerProvider).check();
    if (!verified && !automatic) _message = (s) => s.authStillUnverified;
  });

  Future<void> _resend(String email) => _perform(() async {
    final language = Localizations.localeOf(context).languageCode;
    await ref.read(verificationControllerProvider).resend(email, language);
    _message = (s) => s.authVerificationSent;
  });

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final user = ref.watch(authSessionProvider).asData?.value;
    final email = user?.email ?? '';
    final controller = ref.watch(verificationControllerProvider);
    final seconds = controller.secondsRemaining(email);
    if (seconds > 0 && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (controller.secondsRemaining(email) == 0) {
          timer.cancel();
          _timer = null;
        }
        if (mounted) setState(() {});
      });
    }
    final registrationError = ref.watch(registrationControllerProvider).error;
    return Scaffold(
      body: AppPage(
        children: [
          AppHeader(title: s.verifyEmail, back: false),
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
                  email,
                  textAlign: TextAlign.center,
                  style: AppTypography.heading(20),
                ),
                const SizedBox(height: 12),
                Text(s.verifyHelp, textAlign: TextAlign.center),
                const SizedBox(height: 15),
                AppButton(
                  s.authCheckVerification,
                  onPressed: _busy ? null : () => _check(),
                ),
                TextButton(
                  onPressed: _busy || seconds > 0 ? null : () => _resend(email),
                  child: Text(
                    seconds > 0 ? s.authResendWait(seconds) : s.verifyAgain,
                  ),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () =>
                            _perform(ref.read(loginControllerProvider).signOut),
                  child: Text(s.signOut),
                ),
                if (_busy) const AppLoadingIndicator(),
                if (_message != null)
                  _AuthMessage(_message!(s))
                else if (registrationError is RegistrationSetupFailure &&
                    registrationError.uid == user?.uid)
                  _AuthMessage(s.authRegistrationIncomplete, isError: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AuthenticatedScreen extends ConsumerStatefulWidget {
  const AuthenticatedScreen({super.key});

  @override
  ConsumerState<AuthenticatedScreen> createState() =>
      _AuthenticatedScreenState();
}

class _AuthenticatedScreenState extends ConsumerState<AuthenticatedScreen> {
  bool _busy = false;
  Object? _error;

  Future<void> _signOut() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(loginControllerProvider).signOut();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final user = ref.watch(authSessionProvider).asData?.value;
    return Scaffold(
      body: AppPage(
        children: [
          AppHeader(title: 'SmartCouple', back: false),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.gold,
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  s.authVerified,
                  textAlign: TextAlign.center,
                  style: AppTypography.heading(20),
                ),
                if (user != null)
                  Text(user.name ?? user.email, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                AppButton(s.signOut, onPressed: _busy ? null : _signOut),
                TextButton(
                  onPressed: () => context.push('/language'),
                  child: Text(s.language),
                ),
                if (_busy) const AppLoadingIndicator(),
                if (_error != null)
                  _AuthMessage(_authError(s, _error!), isError: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AuthErrorScreen extends ConsumerWidget {
  const AuthErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      SplashScreen(onRetry: () => ref.invalidate(authSessionProvider));
}

class _AuthMessage extends StatelessWidget {
  const _AuthMessage(this.message, {this.isError = false});
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Semantics(
      liveRegion: true,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: isError
            ? TextStyle(color: Theme.of(context).colorScheme.error)
            : null,
      ),
    ),
  );
}

String _authError(AppLocalizations s, Object error) {
  final code = error is FirebaseAuthException ? error.code : null;
  return switch (code) {
    'email-already-in-use' => s.authDuplicate,
    'invalid-email' => s.authInvalidEmail,
    'weak-password' => s.shortPassword,
    'invalid-credential' ||
    'invalid-login-credentials' ||
    'wrong-password' ||
    'user-not-found' ||
    'user-disabled' => s.authInvalidCredentials,
    'network-request-failed' => s.authNetwork,
    'too-many-requests' => s.authRateLimit,
    'operation-not-allowed' => s.authUnavailable,
    _ => s.authFailure,
  };
}
