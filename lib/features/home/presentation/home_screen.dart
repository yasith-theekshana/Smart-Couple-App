import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/services/demo_state.dart';
import '../../../core/widgets/design_system.dart';
import '../../articles/presentation/article_screens.dart';
import '../../profile/presentation/account_screens.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.strings;
    final session = ref.watch(demoSessionProvider);
    final greeting = session.name.isEmpty ? s.demoCouple : session.name;

    return AppPage(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppLabel(s.welcome, color: AppColors.gold),
                  const SizedBox(height: 3),
                  Text(greeting, style: AppTypography.heading(22)),
                ],
              ),
            ),
            IconButton(
              tooltip: s.profile,
              onPressed: () => showAccountSheet(context),
              icon: const CoupleAvatar(),
            ),
          ],
        ),
        if (session.workspace.isNotEmpty)
          ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: () => context.push('/workspace'),
            title: Text(session.workspace, style: AppTypography.heading(17)),
            subtitle: session.invitation == InvitationStatus.connected
                ? Text(session.partnerEmail)
                : null,
            trailing: const Icon(Icons.chevron_right, color: AppColors.navy),
          ),
        const SizedBox(height: 25),
        _SectionTitle(s.responsibilities),
        _ShortcutRow(
          items: [
            (s.finance, Icons.account_balance_wallet, '/finance'),
            (s.tasks, Icons.cleaning_services, '/tasks'),
          ],
        ),
        const SizedBox(height: 29),
        _SectionTitle(s.extras),
        _ShortcutRow(
          items: [
            (s.shopping, Icons.shopping_cart, '/shopping'),
            (s.calendar, Icons.calendar_month, '/calendar'),
          ],
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push('/articles'),
            child: AppLabel(s.viewAll, color: AppColors.gold),
          ),
        ),
        const ArticlePreview(index: 0, featured: true),
        const SizedBox(height: 20),
        AppCard(
          onTap: () => context.push('/workspace'),
          child: Row(
            children: [
              const Icon(Icons.favorite_border, color: AppColors.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.workspaceOverview,
                  style: AppTypography.heading(18),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 3, bottom: 16),
    child: Text(
      title.toUpperCase(),
      style: AppTypography.heading(12)
          .copyWith(color: AppColors.muted, letterSpacing: 1.6),
    ),
  );
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.items});
  final List<(String, IconData, String)> items;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (label, icon, path) in items) ...[
        if (path == items.last.$3) const SizedBox(width: 12),
        Expanded(
          child: AppCard(
            border: AppColors.gold,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 24),
            onTap: () => context.go(path),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.field,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.navy, size: 21),
                ),
                const SizedBox(height: 13),
                AppLabel(label),
              ],
            ),
          ),
        ),
      ],
    ],
  );
}
