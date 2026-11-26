import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/design_system.dart';
import '../../../core/widgets/editor_dialog.dart';
import '../data/demo_finance.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  int _tab = 0;
  int _month = 4;
  bool _sortByName = false;
  bool _hideDebtMessage = false;
  bool _debtMessageAcknowledged = false;

  List<String> get _partners => ['Florian', 'Sophie', context.strings.both];

  String _name(String name) => switch (name) {
    '@income' => context.strings.income,
    '@rent' => context.strings.rent,
    '@groceries' => context.strings.groceries,
    '@budget' => context.strings.budgets,
    _ => name,
  };

  String _category(ExpenseCategory category) {
    final s = context.strings;
    return switch (category) {
      ExpenseCategory.rent => s.rentCategory,
      ExpenseCategory.groceries => s.groceries,
      ExpenseCategory.subscriptions => s.subscriptions,
      ExpenseCategory.fuel => s.fuel,
      ExpenseCategory.leisure => s.leisure,
      ExpenseCategory.other => s.other,
    };
  }

  String _kind(FinanceKind kind) {
    final s = context.strings;
    return switch (kind) {
      FinanceKind.income => s.income,
      FinanceKind.contribution => s.contributions,
      FinanceKind.expense => s.expenses,
      FinanceKind.budget => s.budgets,
      FinanceKind.settlement => s.settlements,
    };
  }

  Future<void> _edit(
    FinanceKind kind, {
    int? index,
    FinanceEntry? entry,
  }) async {
    final s = context.strings;
    final categories = ExpenseCategory.values.map(_category).toList();
    final values = await showEditor(context, s.financialRecord, [
      editField(s.name, value: entry == null ? '' : _name(entry.name)),
      editField(
        s.amount,
        value: entry?.amount.toString() ?? '',
        input: EditorInput.number,
      ),
      editField(
        s.partner,
        value: _partners[entry?.partner ?? 0],
        input: EditorInput.select,
        options: _partners,
      ),
      editField(
        s.date,
        value: editorDate(entry?.date ?? DateTime(2026, _month, 1)),
        input: EditorInput.date,
      ),
      if (kind == FinanceKind.expense)
        editField(
          s.category,
          value: _category(entry?.category ?? ExpenseCategory.other),
          input: EditorInput.select,
          options: categories,
        ),
    ]);
    if (values == null || !mounted) return;
    final date = DateTime.parse(values[3]);
    ref.read(financeProvider.notifier).save((
      kind: kind,
      name: values[0],
      amount: parseAmount(values[1])!,
      partner: _partners.indexOf(values[2]).clamp(0, 2),
      date: date,
      category: kind == FinanceKind.expense
          ? ExpenseCategory.values[categories.indexOf(values[4])]
          : null,
    ), index: index);
    setState(() => _month = date.month);
  }

  List<(int, FinanceEntry)> _entries(
    List<FinanceEntry> records,
    FinanceKind kind,
  ) {
    final entries = records.indexed
        .where((pair) => pair.$2.kind == kind && pair.$2.date.month == _month)
        .toList();
    entries.sort(
      (a, b) => _sortByName
          ? _name(a.$2.name).compareTo(_name(b.$2.name))
          : a.$2.date.compareTo(b.$2.date),
    );
    return entries;
  }

  double _sum(List<FinanceEntry> entries, FinanceKind kind, [int? partner]) =>
      entries
          .where(
            (entry) =>
                entry.kind == kind &&
                (partner == null || entry.partner == partner),
          )
          .fold(0.0, (sum, entry) => sum + entry.amount);

  Widget _records(List<FinanceEntry> records, FinanceKind kind) {
    final s = context.strings;
    final entries = _entries(records, kind);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: AppLabel(_kind(kind), color: AppColors.muted)),
            IconButton(
              tooltip: s.add,
              onPressed: () => _edit(kind),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        if (entries.isEmpty) const AppEmptyState(),
        for (final (index, entry) in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              onTap: () => _edit(kind, index: index, entry: entry),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name(entry.name),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        AppLabel(
                          _partners[entry.partner],
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Text(
                      euro(context, entry.amount),
                      textAlign: TextAlign.end,
                      style: AppTypography.heading(16),
                    ),
                  ),
                  IconButton(
                    tooltip: s.edit,
                    onPressed: () => _edit(kind, index: index, entry: entry),
                    icon: const Icon(Icons.edit_outlined, size: 17),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _dashboard(List<FinanceEntry> records, List<FinanceEntry> month) {
    final s = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          border: AppColors.gold,
          padding: const EdgeInsets.all(23),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: AppLabel(s.recurring, color: AppColors.gold),
              ),
              const SizedBox(height: 23),
              Text(
                euro(context, _sum(month, FinanceKind.income)),
                style: AppTypography.heading(34),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AppLabel(s.split, color: AppColors.muted),
        for (var partner = 0; partner < 2; partner++)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: AppCard(
              border: AppColors.gold,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, color: AppColors.gold),
                      const SizedBox(width: 8),
                      Expanded(child: AppLabel(_partners[partner])),
                      AppLabel(s.recurring, color: AppColors.gold),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    euro(context, _sum(month, FinanceKind.income, partner)),
                    style: AppTypography.heading(24),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        _records(records, FinanceKind.income),
        _records(records, FinanceKind.contribution),
      ],
    );
  }

  Widget _analysis(List<FinanceEntry> records, List<FinanceEntry> month) {
    final s = context.strings;
    final total = _sum(month, FinanceKind.expense);
    final income = _sum(month, FinanceKind.income);
    final budget = _sum(month, FinanceKind.budget);
    final savings = income - total;
    final status = income > 0 ? '${(savings * 100 / income).round()}%' : '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          border: AppColors.gold,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _chartColumn(
                    s.budgets,
                    budget,
                    math.max(budget, total),
                    const Color(0xff52cd83),
                  ),
                  _chartColumn(
                    s.expenses,
                    total,
                    math.max(budget, total),
                    const Color(0xffef7064),
                  ),
                ],
              ),
              const Divider(color: AppColors.line, height: 20),
              Text(
                s.budgetComparison.toUpperCase(),
                textAlign: TextAlign.center,
                style: AppTypography.heading(13).copyWith(letterSpacing: 0.7),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  _chartSummary(s.savings, euro(context, savings)),
                  const SizedBox(width: 8),
                  _chartSummary(s.status, status),
                  const SizedBox(width: 8),
                  _chartSummary(s.budgets, euro(context, budget)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        _monthSelector(),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppLabel(s.spending),
              const SizedBox(height: 13),
              for (var i = 0; i < _partners.length; i++)
                _bar(
                  _partners[i],
                  _sum(month, FinanceKind.expense, i),
                  total,
                  i == 0 ? AppColors.navy : AppColors.gold,
                ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        if (total > 0)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppLabel(s.category),
                for (final category in ExpenseCategory.values)
                  if (month.any((entry) => entry.category == category))
                    _bar(
                      _category(category),
                      month
                          .where((entry) => entry.category == category)
                          .fold(0.0, (sum, entry) => sum + entry.amount),
                      total,
                      AppColors.gold,
                    ),
              ],
            ),
          ),
        _records(records, FinanceKind.budget),
      ],
    );
  }

  Widget _chartColumn(
    String label,
    double amount,
    double maximum,
    Color color,
  ) => Expanded(
    child: Semantics(
      label: '$label ${euro(context, amount)}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FractionallySizedBox(
            widthFactor: 0.58,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: maximum > 0 ? 175 * amount / maximum : 0,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTypography.label(AppColors.muted, 9),
          ),
        ],
      ),
    ),
  );

  Widget _chartSummary(String label, String amount) => Expanded(
    child: AppCard(
      color: AppColors.field,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTypography.label(AppColors.muted, 8),
          ),
          const SizedBox(height: 4),
          FittedBox(child: Text(amount, style: AppTypography.heading(18))),
        ],
      ),
    ),
  );

  Widget _expenses(List<FinanceEntry> records) {
    final s = context.strings;
    final entries = _entries(records, FinanceKind.expense);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: AppLabel(s.filters, color: AppColors.muted)),
            IconButton.filled(
              tooltip: s.add,
              onPressed: () => _edit(FinanceKind.expense),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _monthSelector()),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<bool>(
                isExpanded: true,
                initialValue: _sortByName,
                decoration: const InputDecoration(),
                items: [
                  DropdownMenuItem(
                    value: false,
                    child: Text(s.sortDate, overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: true,
                    child: Text(s.sortName, overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _sortByName = value ?? false),
              ),
            ),
          ],
        ),
        if (entries.isEmpty)
          const AppEmptyState()
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ColoredBox(
                  color: AppColors.field,
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: AppLabel(
                            s.transaction,
                            color: AppColors.muted,
                          ),
                        ),
                        const Expanded(
                          child: AppLabel('Florian', color: AppColors.gold),
                        ),
                        const Expanded(child: AppLabel('Sophie')),
                      ],
                    ),
                  ),
                ),
                for (final (index, entry) in entries) ...[
                  const Divider(height: 1, color: AppColors.line),
                  InkWell(
                    onTap: () =>
                        _edit(FinanceKind.expense, index: index, entry: entry),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 15,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              _name(entry.name),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          for (var partner = 0; partner < 2; partner++)
                            Expanded(
                              child: Text(
                                euro(
                                  context,
                                  entry.partner == partner
                                      ? entry.amount
                                      : entry.partner == 2
                                      ? entry.amount / 2
                                      : 0,
                                ),
                                style: AppTypography.label(
                                  partner == 0
                                      ? AppColors.ink
                                      : AppColors.muted,
                                  9,
                                ).copyWith(letterSpacing: 0),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _bar(String title, double amount, double total, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text(title)),
                Text(
                  euro(context, amount),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : (amount / total).clamp(0.0, 1.0),
                minHeight: 10,
                color: color,
                backgroundColor: AppColors.field,
              ),
            ),
          ],
        ),
      );

  Widget _monthSelector() => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: DropdownButtonFormField<int>(
      key: ValueKey(_month),
      initialValue: _month,
      isExpanded: true,
      decoration: InputDecoration(labelText: context.strings.month),
      items: [
        for (var month = 1; month <= 12; month++)
          DropdownMenuItem(
            value: month,
            child: Text(
              DateFormat.MMMM(context.languageCode)
                  .format(DateTime(2026, month)),
            ),
          ),
      ],
      onChanged: (value) {
        if (value != null) setState(() => _month = value);
      },
    ),
  );

  Widget _debts(List<FinanceEntry> records, List<FinanceEntry> month) {
    final s = context.strings;
    if (!_hideDebtMessage && !_debtMessageAcknowledged) {
      return AppCard(
        color: AppColors.cream,
        border: AppColors.gold,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.favorite, color: AppColors.gold, size: 32),
            const SizedBox(height: 12),
            Text(s.debtMessage, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            AppButton(
              s.continueLabel,
              onPressed: () => setState(() => _debtMessageAcknowledged = true),
            ),
            TextButton(
              onPressed: () => setState(() => _hideDebtMessage = true),
              child: Text(s.hideMessage),
            ),
          ],
        ),
      );
    }
    final amount =
        (_sum(month, FinanceKind.expense, 0) -
                _sum(month, FinanceKind.expense, 1)) /
            2 -
        _sum(month, FinanceKind.settlement, 1) +
        _sum(month, FinanceKind.settlement, 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          border: AppColors.gold,
          child: Column(
            children: [
              AppLabel(s.balances),
              const SizedBox(height: 10),
              Text(amount >= 0 ? 'Sophie → Florian' : 'Florian → Sophie'),
              Text(
                euro(context, amount.abs()),
                style: AppTypography.heading(29),
              ),
            ],
          ),
        ),
        _records(records, FinanceKind.settlement),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final records = ref.watch(financeProvider);
    final month = records.where((entry) => entry.date.month == _month).toList();
    final labels = [s.dashboard, s.expenses, s.debts, s.analysis];
    return AppPage(
      children: [
        AppHeader(title: s.finance),
        Row(
          children: [
            for (final (index, label) in labels.indexed)
              Expanded(
                child: InkWell(
                  onTap: () => setState(() {
                    _tab = index;
                    _debtMessageAcknowledged = false;
                  }),
                  child: Container(
                    alignment: Alignment.center,
                    constraints: const BoxConstraints(minHeight: 44),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: index == _tab
                              ? AppColors.gold
                              : AppColors.line,
                          width: 2,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Text(
                      label.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppTypography.label(
                        index == _tab ? AppColors.gold : AppColors.muted,
                        8,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        switch (_tab) {
          0 => _dashboard(records, month),
          1 => _expenses(records),
          2 => _debts(records, month),
          _ => _analysis(records, month),
        },
      ],
    );
  }
}
