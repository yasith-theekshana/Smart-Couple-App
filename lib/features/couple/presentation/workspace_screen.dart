import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/services/demo_state.dart';
import '../../../core/widgets/design_system.dart';

class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({this.settings = false, super.key});
  final bool settings;

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  final _form = GlobalKey<FormState>();
  final _value = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.settings) _value.text = ref.read(demoSessionProvider).workspace;
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final session = ref.watch(demoSessionProvider);
    final controller = ref.read(demoSessionProvider.notifier);
    final creating = session.workspace.isEmpty || widget.settings;
    final status = session.invitation;
    final stateTitle = switch (status) {
      InvitationStatus.idle => s.invitePartner,
      InvitationStatus.pending => s.pendingInvitation,
      InvitationStatus.incoming => s.incomingInvitation,
      InvitationStatus.connected => s.connected,
      InvitationStatus.declined => s.invitationDeclined,
    };
    final canInvite =
        status == InvitationStatus.idle || status == InvitationStatus.declined;
    void submit() {
      if (!_form.currentState!.validate()) return;
      if (creating) {
        controller.createWorkspace(_value.text.trim());
        if (widget.settings) {
          context.canPop() ? context.pop() : context.go('/workspace');
        } else {
          _value.clear();
        }
      } else {
        controller.invite(_value.text.trim());
        _value.clear();
      }
    }

    return Scaffold(
      body: AppPage(
        children: [
          AppHeader(title: widget.settings ? s.workspaceSettings : s.workspace),
          AppCard(
            border: AppColors.gold,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  status == InvitationStatus.connected
                      ? Icons.favorite
                      : Icons.people_outline,
                  color: AppColors.gold,
                  size: 42,
                ),
                const SizedBox(height: 12),
                Text(
                  creating ? s.createWorkspace : stateTitle,
                  style: AppTypography.heading(24),
                  textAlign: TextAlign.center,
                ),
                if (!creating) ...[
                  const SizedBox(height: 10),
                  Text(session.workspace, textAlign: TextAlign.center),
                  if (!canInvite)
                    Text(session.partnerEmail, textAlign: TextAlign.center),
                ],
                if (creating || canInvite) ...[
                  const SizedBox(height: 15),
                  if (!creating) Text(s.inviteHelp),
                  const SizedBox(height: 12),
                  Form(
                    key: _form,
                    child: AppTextField(
                      label: creating ? s.name : s.partnerEmail,
                      controller: _value,
                      keyboard: creating ? null : TextInputType.emailAddress,
                      validator: (value) {
                        if (creating) return requiredText(context, value);
                        return emailError(context, value) ??
                            (value!.trim().toLowerCase() ==
                                    session.email.toLowerCase()
                                ? s.invalidPartner
                                : null);
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  AppButton(
                    creating ? s.save : s.sendInvite,
                    onPressed: submit,
                  ),
                ],
                if (!creating && status == InvitationStatus.pending) ...[
                  const SizedBox(height: 15),
                  AppButton(
                    s.previewIncoming,
                    onPressed: controller.previewIncoming,
                    outlined: true,
                  ),
                ],
                if (!creating && status == InvitationStatus.incoming) ...[
                  const SizedBox(height: 15),
                  AppButton(s.accept, onPressed: controller.accept),
                  AppButton(
                    s.decline,
                    onPressed: controller.decline,
                    outlined: true,
                  ),
                ],
                if (!creating && status == InvitationStatus.connected) ...[
                  const SizedBox(height: 15),
                  AppButton(s.openWorkspace, onPressed: () => context.go('/')),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
