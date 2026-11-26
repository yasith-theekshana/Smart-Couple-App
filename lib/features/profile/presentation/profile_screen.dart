import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/design_system.dart';
import '../../authentication/application/auth_controllers.dart';
import '../../authentication/application/auth_repository.dart';
import '../application/profile_providers.dart';
import '../data/user_profile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).asData?.value;
    final state = ref.watch(activeProfileProvider);
    final profile = state.asData?.value;
    return Scaffold(
      body: AppPage(
        children: [
          AppHeader(title: context.strings.profile, back: false),
          if (state.hasError)
            _ProfileStatus(error: state.error)
          else if (state.isLoading ||
              session == null ||
              session.uid != profile?.uid)
            state.hasValue &&
                    !state.isLoading &&
                    session?.verified == true &&
                    profile == null
                ? const _ProfileStatus()
                : const AppLoadingIndicator()
          else
            _ProfileDetails(key: ValueKey(profile!.uid), profile: profile),
        ],
      ),
    );
  }
}

class _ProfileStatus extends ConsumerWidget {
  const _ProfileStatus({this.error});
  final Object? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.strings;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            error == null ? s.profileMissing : _profileError(context, error!),
          ),
          AppButton(
            s.authRetry,
            onPressed: () => ref.invalidate(activeProfileProvider),
          ),
          const _SignOutButton(),
        ],
      ),
    );
  }
}

class _ProfileDetails extends ConsumerStatefulWidget {
  const _ProfileDetails({required this.profile, super.key});
  final UserProfile profile;

  @override
  ConsumerState<_ProfileDetails> createState() => _ProfileDetailsState();
}

class _ProfileDetailsState extends ConsumerState<_ProfileDetails> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  String _language = 'en';
  bool _editing = false;
  bool _busy = false;
  bool _saved = false;
  Object? _error;

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  void _edit() => setState(() {
    _username.text = widget.profile.username;
    _language = widget.profile.preferredLanguage;
    _editing = true;
    _saved = false;
    _error = null;
  });

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await _perform(() async {
      final synced = await ref
          .read(profileEditorProvider)
          .save(widget.profile, _username.text, _language);
      if (!mounted) return;
      setState(() {
        _editing = false;
        _saved = true;
        if (!synced) _error = const _NameSyncFailure();
      });
    });
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _saved = false;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final profile = widget.profile;
    final session = ref.watch(authSessionProvider).asData?.value;
    final authName = session?.name;
    final initials = profile.username
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();
    final date = session?.accountCreatedAt ?? profile.createdAt;
    return AppCard(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: 31,
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.navy,
                child: Text(initials, style: AppTypography.heading(20)),
              ),
            ),
            const SizedBox(height: 16),
            if (_editing)
              AppTextField(
                label: s.username,
                controller: _username,
                enabled: !_busy,
                validator: (value) => normalizeUsername(value ?? '') == null
                    ? s.profileUsernameLength
                    : null,
              )
            else
              _ProfileField(s.username, profile.username),
            _ProfileField(s.email, profile.email),
            _ProfileField(s.verifyEmail, s.authVerified),
            if (date != null)
              _ProfileField(
                s.profileCreated,
                MaterialLocalizations.of(context).formatMediumDate(date),
              ),
            if (_editing)
              DropdownButtonFormField<String>(
                initialValue: _language,
                decoration: InputDecoration(labelText: s.language),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'fr', child: Text('Fran\u00e7ais')),
                ],
                onChanged: _busy
                    ? null
                    : (language) => setState(() => _language = language!),
              )
            else
              _ProfileField(
                s.language,
                profile.preferredLanguage == 'fr' ? 'Fran\u00e7ais' : 'English',
              ),
            const SizedBox(height: 12),
            if (_editing) ...[
              AppButton(s.profileSaveChanges, onPressed: _busy ? null : _save),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _editing = false;
                        _error = null;
                      }),
                child: Text(s.cancel),
              ),
            ] else ...[
              AppButton(s.profileEdit, onPressed: _busy ? null : _edit),
              if (authName != profile.username || _error is _NameSyncFailure)
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _perform(() async {
                          await ref
                              .read(profileEditorProvider)
                              .synchronizeName(profile);
                          if (mounted) setState(() => _saved = true);
                        }),
                  child: Text(s.profileSyncName),
                ),
            ],
            if (_busy) const AppLoadingIndicator(),
            if (_saved || _error != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  _error is _NameSyncFailure
                      ? s.profileSavedSyncFailed
                      : _error != null
                      ? _profileError(context, _error!)
                      : s.profileSaved,
                  textAlign: TextAlign.center,
                ),
              ),
            _SignOutButton(disabled: _busy),
          ],
        ),
      ),
    );
  }
}

class _NameSyncFailure {
  const _NameSyncFailure();
}

class _ProfileField extends StatelessWidget {
  const _ProfileField(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppLabel(label, color: AppColors.muted),
        Text(value),
      ],
    ),
  );
}

class _SignOutButton extends ConsumerStatefulWidget {
  const _SignOutButton({this.disabled = false});
  final bool disabled;

  @override
  ConsumerState<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends ConsumerState<_SignOutButton> {
  bool _busy = false;

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      await ref.read(loginControllerProvider).signOut();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_profileError(context, error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppButton(
    context.strings.signOut,
    outlined: true,
    onPressed: _busy || widget.disabled ? null : _signOut,
  );
}

String _profileError(BuildContext context, Object error) {
  final s = context.strings;
  final code = error is FirebaseException ? error.code : null;
  return switch (code) {
    'permission-denied' => s.profilePermission,
    'unavailable' ||
    'deadline-exceeded' ||
    'network-request-failed' => s.authNetwork,
    _ => s.profileFailure,
  };
}
