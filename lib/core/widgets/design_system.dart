import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

extension LocalizedContext on BuildContext {
  AppLocalizations get strings => AppLocalizations.of(this);
  String get languageCode => Localizations.localeOf(this).languageCode;
}

class AppLabel extends StatelessWidget {
  const AppLabel(this.text, {this.color = AppColors.navy, super.key});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: AppTypography.label(color));
}

class AppHeader extends StatelessWidget {
  const AppHeader({
    required this.title,
    this.eyebrow,
    this.action,
    this.back = true,
    this.onBack,
    super.key,
  });

  final String title;
  final String? eyebrow;
  final Widget? action;
  final bool back;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      children: [
        if (back)
          IconButton(
            tooltip: context.strings.back,
            onPressed:
                onBack ??
                () => context.canPop() ? context.pop() : context.go('/'),
            icon: const Icon(Icons.chevron_left, color: AppColors.navy),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) AppLabel(eyebrow!, color: AppColors.muted),
              Text(title, style: AppTypography.heading()),
            ],
          ),
        ),
        ?action,
      ],
    ),
  );
}

class AppPage extends StatelessWidget {
  const AppPage({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: LayoutBuilder(
      builder: (context, constraints) => ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.page +
              ((constraints.maxWidth - 560).clamp(0.0, 2000.0) / 2),
          16,
          AppSpacing.page +
              ((constraints.maxWidth - 560).clamp(0.0, 2000.0) / 2),
          28 + MediaQuery.paddingOf(context).bottom,
        ),
        children: children,
      ),
    ),
  );
}

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.paper,
    this.border = AppColors.line,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      side: BorderSide(color: border),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100d2840),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: color,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class AppButton extends StatelessWidget {
  const AppButton(
    this.label, {
    required this.onPressed,
    this.icon,
    this.outlined = false,
    this.compact = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = compact && icon != null
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15),
              const SizedBox(height: 3),
              Text(label.toUpperCase(), textAlign: TextAlign.center),
            ],
          )
        : Text(label.toUpperCase(), textAlign: TextAlign.center);
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 46)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: compact ? 4 : 14, vertical: 8),
      ),
      textStyle: WidgetStatePropertyAll(
        AppTypography.label(
          AppColors.navy,
          compact ? 8 : 11,
        ).copyWith(letterSpacing: compact ? 0 : 0.6),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return outlined
        ? OutlinedButton(
            onPressed: onPressed,
            style: style.copyWith(
              side: const WidgetStatePropertyAll(
                BorderSide(color: AppColors.gold),
              ),
            ),
            child: content,
          )
        : FilledButton(onPressed: onPressed, style: style, child: content);
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    required this.controller,
    this.validator,
    this.keyboard,
    this.obscure = false,
    this.suffixIcon,
    this.enabled = true,
    this.lines = 1,
    super.key,
  });
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboard;
  final bool obscure;
  final Widget? suffixIcon;
  final bool enabled;
  final int lines;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboard,
    obscureText: obscure,
    maxLines: lines,
    enabled: enabled,
    decoration: InputDecoration(labelText: label, suffixIcon: suffixIcon),
  );
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    this.message,
    this.icon = Icons.inbox_outlined,
    super.key,
  });
  final String? message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Column(
      children: [
        Icon(icon, color: AppColors.gold, size: 32),
        const SizedBox(height: 10),
        Text(message ?? context.strings.empty, textAlign: TextAlign.center),
      ],
    ),
  );
}

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.gold));
}

class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.title,
    required this.child,
    required this.actions,
    super.key,
  });
  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.paper,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: AppColors.gold),
    ),
    title: Text(title, style: AppTypography.heading(22)),
    scrollable: true,
    content: child,
    actions: actions,
  );
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.index,
    required this.onSelect,
    super.key,
  });
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final labels = [s.home, s.finance, s.shopping, s.agenda, s.tasks];
    const icons = [
      Icons.home_rounded,
      Icons.account_balance_wallet_rounded,
      Icons.shopping_cart_rounded,
      Icons.calendar_month_rounded,
      Icons.cleaning_services,
    ];
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              for (var i = 0; i < icons.length; i++)
                Expanded(
                  child: Semantics(
                    selected: i == index,
                    button: true,
                    label: labels[i],
                    child: Tooltip(
                      message: labels[i],
                      child: InkWell(
                        onTap: () => onSelect(i),
                        child: SizedBox(
                          height: 62,
                          child: Column(
                            children: [
                              Container(
                                width: 44,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: i == index
                                      ? const Color(0xffe6e5d8)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(
                                  icons[i],
                                  color: i == index
                                      ? AppColors.navy
                                      : AppColors.gold,
                                ),
                              ),
                              if (i == index)
                                Flexible(
                                  child: Text(
                                    labels[i].toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.label(
                                      AppColors.navy,
                                      8,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String? requiredText(BuildContext context, String? value) =>
    value == null || value.trim().isEmpty
    ? context.strings.requiredField
    : null;

String? emailError(BuildContext context, String? value) =>
    requiredText(context, value) ??
    (RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value!.trim())
        ? null
        : context.strings.invalidEmail);

double? parseAmount(String? value) =>
    double.tryParse((value ?? '').trim().replaceAll(',', '.'));

String euro(BuildContext context, num amount) {
  final value = amount.toStringAsFixed(2);
  return context.languageCode == 'fr'
      ? '${value.replaceAll('.', ',')} €'
      : '€$value';
}

Future<bool> confirmDelete(BuildContext context) async {
  final s = context.strings;
  return await showDialog<bool>(
        context: context,
        builder: (context) => AppDialog(
          title: s.delete,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.cancel),
            ),
            AppButton(s.delete, onPressed: () => Navigator.pop(context, true)),
          ],
          child: Text(s.deleteConfirm),
        ),
      ) ??
      false;
}
