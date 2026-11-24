import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/demo_state.dart';

enum FinanceKind { income, contribution, expense, budget, settlement }

enum ExpenseCategory { rent, groceries, subscriptions, fuel, leisure, other }

typedef FinanceEntry = ({
  FinanceKind kind,
  String name,
  double amount,
  int partner,
  DateTime date,
  ExpenseCategory? category,
});

final financeProvider =
    NotifierProvider<DemoRecords<FinanceEntry>, List<FinanceEntry>>(
      () => DemoRecords(
        () => [
          (
            kind: FinanceKind.income,
            category: null,
            name: '@income',
            amount: 3000,
            partner: 0,
            date: DateTime(2026, 4, 1),
          ),
          (
            kind: FinanceKind.income,
            category: null,
            name: '@income',
            amount: 2800,
            partner: 1,
            date: DateTime(2026, 4, 1),
          ),
          (
            kind: FinanceKind.expense,
            category: ExpenseCategory.rent,
            name: '@rent',
            amount: 1250,
            partner: 0,
            date: DateTime(2026, 4, 1),
          ),
          (
            kind: FinanceKind.expense,
            category: ExpenseCategory.subscriptions,
            name: 'Netflix',
            amount: 17.99,
            partner: 0,
            date: DateTime(2026, 4, 3),
          ),
          (
            kind: FinanceKind.budget,
            category: null,
            name: '@budget',
            amount: 5800,
            partner: 2,
            date: DateTime(2026, 4, 1),
          ),
          (
            kind: FinanceKind.contribution,
            category: null,
            name: '@groceries',
            amount: 100,
            partner: 1,
            date: DateTime(2026, 4, 1),
          ),
        ],
      ),
    );
