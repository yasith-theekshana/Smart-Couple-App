import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/services/demo_state.dart';
import '../../../core/widgets/design_system.dart';

class CoupleAvatar extends ConsumerWidget {
  const CoupleAvatar({this.size = 40, super.key});
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.gold, width: 1.5),
      color: AppColors.cream,
    ),
    child: ClipOval(
      child: ref.watch(profilePhotoProvider)
          ? Image.asset('assets/images/couple.jpg', fit: BoxFit.cover)
          : const Icon(Icons.favorite, color: AppColors.navy),
    ),
  );
}

Future<void> showAccountSheet(BuildContext context) async {
  final destination = await showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    scrollControlDisabledMaxHeightRatio: 0.72,
    backgroundColor: AppColors.paper,
    barrierColor: const Color(0x801f4e79),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      side: BorderSide(color: AppColors.gold),
    ),
    showDragHandle: true,
    builder: (context) => const _AccountSheet(),
  );
  if (destination != null && context.mounted) context.push(destination);
}

class _AccountSheet extends ConsumerWidget {
  const _AccountSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.strings;
    final name = ref.watch(demoSessionProvider).name;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: CoupleAvatar(size: 56)),
            const SizedBox(height: 8),
            Text(
              name.isEmpty ? s.demoCouple : name,
              style: AppTypography.heading(),
              textAlign: TextAlign.center,
            ),
            Center(child: AppLabel(s.premium, color: AppColors.gold)),
            const SizedBox(height: 16),
            AppCard(
              color: AppColors.field,
              child: Column(
                children: [AppLabel(s.language), const _LanguageOptions()],
              ),
            ),
            TextButton(
              onPressed: ref.read(profilePhotoProvider.notifier).toggle,
              child: Text(s.choosePhoto),
            ),
            for (final (label, path) in [
              (s.profile, '/profile'),
              (s.notifications, '/notifications'),
              (s.settings, '/settings'),
            ])
              AppButton(
                label,
                outlined: true,
                onPressed: () => Navigator.pop(context, path),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOptions extends ConsumerWidget {
  const _LanguageOptions();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Wrap(
    spacing: 8,
    children: [
      for (final (code, name) in [
        ('fr', 'Français (FR)'),
        ('en', 'English (EN)'),
      ])
        ChoiceChip(
          label: Text(name),
          selected: context.languageCode == code,
          showCheckmark: false,
          backgroundColor: AppColors.paper,
          selectedColor: AppColors.navy,
          side: const BorderSide(color: AppColors.line),
          labelStyle: TextStyle(
            color: context.languageCode == code ? Colors.white : AppColors.navy,
          ),
          onSelected: (_) =>
              ref.read(localeProvider.notifier).select(Locale(code)),
        ),
    ],
  );
}

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AppPage(
      children: [
        AppHeader(title: context.strings.language),
        const AppCard(child: _LanguageOptions()),
      ],
    ),
  );
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.strings;
    return Scaffold(
      body: AppPage(
        children: [
          AppHeader(title: s.settings),
          for (final (label, icon, path) in [
            (s.language, Icons.language, '/language'),
            (s.workspaceSettings, Icons.people, '/workspace/settings'),
            (s.notifications, Icons.notifications_outlined, '/notifications'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                onTap: () => context.push(path),
                child: Row(
                  children: [
                    Icon(icon, color: AppColors.gold),
                    const SizedBox(width: 12),
                    Expanded(child: Text(label)),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          AppButton(
            s.signOut,
            outlined: true,
            onPressed: () {
              ref.read(demoSessionProvider.notifier).signOut();
              context.go('/welcome');
            },
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    final session = ref.read(demoSessionProvider);
    _name = TextEditingController(text: session.name);
    _email = TextEditingController(text: session.email);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Scaffold(
      body: AppPage(
        children: [
          AppHeader(title: s.profile),
          AppCard(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: CoupleAvatar(size: 62)),
                  TextButton(
                    onPressed: ref.read(profilePhotoProvider.notifier).toggle,
                    child: Text(s.choosePhoto),
                  ),
                  AppTextField(
                    label: s.username,
                    controller: _name,
                    validator: (value) => requiredText(context, value),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: s.email,
                    controller: _email,
                    keyboard: TextInputType.emailAddress,
                    validator: (value) => emailError(context, value),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    s.save,
                    onPressed: () {
                      if (!_form.currentState!.validate()) return;
                      ref
                          .read(demoSessionProvider.notifier)
                          .updateProfile(_name.text.trim(), _email.text.trim());
                      if (context.canPop()) context.pop();
                    },
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

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.strings;
    final session = ref.watch(demoSessionProvider);
    final incoming = session.invitation == InvitationStatus.incoming;
    return Scaffold(
      body: AppPage(
        children: [
          AppHeader(title: s.notifications),
          AppCard(
            onTap: () => context.push('/workspace'),
            child: Row(
              children: [
                const Icon(Icons.notifications_outlined, color: AppColors.gold),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    incoming ? s.incomingInvitation : s.demoNotification,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
