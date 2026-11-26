import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/design_system.dart';
import '../../profile/application/profile_providers.dart';
import '../../profile/presentation/profile_screen.dart';
import '../application/workspace_providers.dart';
import '../data/couple_workspace.dart';

class PrivateWorkspaceScreen extends ConsumerWidget {
  const PrivateWorkspaceScreen({this.settings = false, super.key});

  final bool settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.strings;
    final profile = ref.watch(activeProfileProvider).asData?.value;
    final workspaceState = ref.watch(currentWorkspaceProvider);
    final workspace = workspaceState.asData?.value;
    final id = profile?.coupleId;
    final loaded =
        id != null && workspace?.id == id && workspace!.hasMember(profile!.uid);
    return Scaffold(
      body: AppPage(
        children: [
          AppHeader(
            title: settings ? s.workspaceSettings : s.workspace,
            back: settings,
            onBack: () => context.go('/workspace'),
          ),
          if (profile == null)
            const AppLoadingIndicator()
          else if (id == null)
            _WorkspaceForm(key: ValueKey(profile.uid), uid: profile.uid)
          else if (workspaceState.hasError ||
              (!workspaceState.isLoading && !loaded))
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    workspaceState.hasError
                        ? _workspaceError(context, workspaceState.error!)
                        : s.privateWorkspaceUnavailable,
                  ),
                  AppButton(
                    s.authRetry,
                    onPressed: () => ref.invalidate(currentWorkspaceProvider),
                  ),
                  const _ProfileLink(),
                  const AccountSignOutButton(),
                ],
              ),
            )
          else if (!loaded)
            const AppLoadingIndicator()
          else if (settings && workspace.isCreator(profile.uid))
            _WorkspaceForm(
              key: ValueKey(workspace.id),
              uid: profile.uid,
              workspace: workspace,
            )
          else
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(workspace.name, style: AppTypography.heading(26)),
                  const SizedBox(height: 12),
                  _WorkspaceField(s.username, profile.username),
                  _WorkspaceField(s.privateCurrency, workspace.currency),
                  _WorkspaceField(
                    s.privateMembers,
                    '${workspace.memberCount} / 2',
                  ),
                  _WorkspaceField(
                    s.privateMembership,
                    workspace.isCreator(profile.uid)
                        ? s.privateCreator
                        : s.privateMember,
                  ),
                  if (workspace.createdAt case final date?)
                    _WorkspaceField(
                      s.privateWorkspaceCreated,
                      MaterialLocalizations.of(context).formatMediumDate(date),
                    ),
                  if (!workspace.hasPartner) ...[
                    const SizedBox(height: 12),
                    Text(s.privatePartnerPending),
                  ],
                  const SizedBox(height: 12),
                  if (workspace.isCreator(profile.uid))
                    AppButton(
                      s.workspaceSettings,
                      onPressed: () => context.go('/workspace/settings'),
                    ),
                  const _ProfileLink(),
                  const AccountSignOutButton(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WorkspaceField extends StatelessWidget {
  const _WorkspaceField(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppLabel(label, color: AppColors.muted),
        Text(value),
      ],
    ),
  );
}

class _ProfileLink extends StatelessWidget {
  const _ProfileLink();

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => context.go('/profile'),
    child: Text(context.strings.profile),
  );
}

class _WorkspaceForm extends ConsumerStatefulWidget {
  const _WorkspaceForm({required this.uid, this.workspace, super.key});

  final String uid;
  final CoupleWorkspace? workspace;

  @override
  ConsumerState<_WorkspaceForm> createState() => _WorkspaceFormState();
}

class _WorkspaceFormState extends ConsumerState<_WorkspaceForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.workspace?.name);
  late String _currency =
      widget.workspace?.currency ?? defaultWorkspaceCurrency;
  bool _saving = false;
  bool _created = false;
  Object? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || _created || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final controller = ref.read(workspaceControllerProvider);
      final workspace = widget.workspace;
      if (workspace == null) {
        await controller.create(widget.uid, _name.text, _currency);
        if (mounted) setState(() => _created = true);
      } else {
        await controller.update(widget.uid, workspace, _name.text, _currency);
        if (mounted) context.go('/workspace');
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final busy = _saving || _created;
    return AppCard(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.workspace == null)
              Text(s.createWorkspace, style: AppTypography.heading(20)),
            AppTextField(
              label: s.privateWorkspaceName,
              controller: _name,
              enabled: !busy,
              validator: (value) => normalizeWorkspaceName(value ?? '') == null
                  ? s.privateWorkspaceNameInvalid
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: InputDecoration(labelText: s.privateCurrency),
              items: [
                for (final currency in workspaceCurrencies)
                  DropdownMenuItem(value: currency, child: Text(currency)),
              ],
              validator: (value) => workspaceCurrencies.contains(value)
                  ? null
                  : s.privateCurrencyInvalid,
              onChanged: busy
                  ? null
                  : (value) => setState(() => _currency = value!),
            ),
            const SizedBox(height: 12),
            AppButton(
              widget.workspace == null
                  ? s.privateCreateWorkspace
                  : s.profileSaveChanges,
              onPressed: busy ? null : _submit,
            ),
            if (busy) const AppLoadingIndicator(),
            if (_error case final error?)
              Semantics(
                liveRegion: true,
                child: Text(_workspaceError(context, error)),
              ),
            if (widget.workspace != null)
              TextButton(
                onPressed: busy ? null : () => context.go('/workspace'),
                child: Text(s.cancel),
              )
            else if (!busy)
              const _ProfileLink(),
            AccountSignOutButton(disabled: _saving),
          ],
        ),
      ),
    );
  }
}

String _workspaceError(BuildContext context, Object error) {
  final s = context.strings;
  return switch (error is FirebaseException ? error.code : null) {
    'permission-denied' => s.privateWorkspacePermission,
    'unavailable' ||
    'deadline-exceeded' ||
    'network-request-failed' => s.authNetwork,
    _ => s.privateWorkspaceFailure,
  };
}
