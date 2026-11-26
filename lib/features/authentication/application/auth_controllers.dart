import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';

final registrationControllerProvider =
    NotifierProvider<RegistrationController, AsyncValue<void>>(
      RegistrationController.new,
    );
final loginControllerProvider = Provider(
  (ref) => LoginController(ref.watch(authRepositoryProvider)),
);
final passwordResetControllerProvider = Provider(
  (ref) => PasswordResetController(ref.watch(authRepositoryProvider)),
);
final verificationControllerProvider = Provider(
  (ref) => VerificationController(ref.watch(authRepositoryProvider)),
);

class RegistrationController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> submit(
    String name,
    String email,
    String password,
    String language,
  ) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(authRepositoryProvider)
          .register(name, email, password, language);
      ref.read(verificationControllerProvider).recordInitialSend(email);
      state = const AsyncData(null);
    } catch (error, stack) {
      state = AsyncError(error, stack);
      rethrow;
    }
  }
}

class LoginController {
  LoginController(this._repository);
  final AuthRepository _repository;

  Future<void> submit(String email, String password) =>
      _repository.login(email, password);
  Future<void> signOut() => _repository.signOut();
}

class PasswordResetController {
  PasswordResetController(this._repository);
  final AuthRepository _repository;

  Future<void> submit(String email, String language) =>
      _repository.resetPassword(email, language);
}

class VerificationController {
  VerificationController(this._repository);
  final AuthRepository _repository;
  final _resendAfter = <String, DateTime>{};

  static const cooldown = Duration(seconds: 60);

  int secondsRemaining(String email) {
    final remaining = _resendAfter[email.toLowerCase()]?.difference(
      DateTime.now(),
    );
    if (remaining == null || remaining <= Duration.zero) return 0;
    return (remaining.inMilliseconds / 1000).ceil();
  }

  void recordInitialSend(String email) {
    _resendAfter[email.toLowerCase()] = DateTime.now().add(cooldown);
  }

  Future<void> resend(String email, String language) async {
    if (secondsRemaining(email) > 0) return;
    recordInitialSend(email);
    try {
      await _repository.sendVerification(language);
    } catch (_) {
      _resendAfter.remove(email.toLowerCase());
      rethrow;
    }
  }

  Future<bool> check() => _repository.refreshVerification();
}
