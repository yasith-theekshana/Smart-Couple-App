import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/design_system.dart';
import '../../../core/widgets/editor_dialog.dart';
import '../data/demo_shopping.dart';

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  static const _units = ['u', 'kg', 'g', 'L', 'ml', 'paq'];
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _price = TextEditingController(text: '0');
  String _unit = 'u';
  bool _pendingOnly = false;

  @override
  void dispose() {
    for (final controller in [_name, _quantity, _price]) {
      controller.dispose();
    }
    super.dispose();
  }

  String _label(String value) {
    final s = context.strings;
    return switch (value) {
      '@main' => s.mainList,
      '@bread' => s.bread,
      '@milk' => s.milk,
      '@detergent' => s.detergent,
      '@apples' => s.apples,
      _ => value,
    };
  }

  Future<void> _create() async {
    final s = context.strings;
    final result = await showEditor(context, s.listName, [editField(s.name)]);
    if (result != null && mounted) {
      ref.read(shoppingProvider.notifier).create(result.first);
    }
  }

  Future<void> _edit(ShoppingItem item) async {
    final s = context.strings;
    final result = await showEditor(context, s.edit, [
      editField(s.name, value: _label(item.name)),
      editField(
        s.quantity,
        value: item.quantity.toString(),
        input: EditorInput.positiveNumber,
      ),
      editField(
        s.unit,
        value: item.unit,
        input: EditorInput.select,
        options: _units,
      ),
      editField(
        s.estimatedPrice,
        value: item.price.toString(),
        input: EditorInput.number,
      ),
    ]);
    if (result == null || !mounted) return;
    ref
        .read(shoppingProvider.notifier)
        .save(
          existing: item,
          name: result[0],
          quantity: parseAmount(result[1])!,
          unit: result[2],
          price: parseAmount(result[3])!,
        );
  }

  void _add() {
    if (!_form.currentState!.validate()) return;
    ref
        .read(shoppingProvider.notifier)
        .save(
          name: _name.text.trim(),
          quantity: parseAmount(_quantity.text)!,
          unit: _unit,
          price: parseAmount(_price.text)!,
        );
    _name.clear();
    _quantity.text = '1';
    _price.text = '0';
    FocusScope.of(context).unfocus();
  }

  String? _number(String? value, {bool quantity = false}) {
    final number = parseAmount(value);
    return number == null ||
            !number.isFinite ||
            number < 0 ||
            (quantity && number == 0)
        ? context.strings.invalidNumber
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final state = ref.watch(shoppingProvider);
    final controller = ref.read(shoppingProvider.notifier);
    final list = state.lists.firstWhere((list) => list.id == state.selected);
    final items = list.items;
    final pending = items.where((item) => !item.purchased).length;
    final visible = items
        .where((item) => !_pendingOnly || !item.purchased)
        .toList();
    return AppPage(
      children: [
        AppHeader(title: s.shopping, eyebrow: _label(list.name)),
        AppCard(
          color: AppColors.navy,
          border: AppColors.gold,
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              _stat(
                s.total,
                '${items.length}',
                onTap: () => setState(() => _pendingOnly = false),
              ),
              _stat(
                s.toBuy,
                '$pending',
                gold: true,
                onTap: () => setState(() => _pendingOnly = !_pendingOnly),
              ),
              _stat(
                s.estimatedBudget,
                euro(
                  context,
                  items.fold(
                    0.0,
                    (sum, item) => sum + item.quantity * item.price,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            Expanded(
              child: AppButton(
                s.createList,
                onPressed: _create,
                icon: Icons.post_add,
                outlined: true,
                compact: true,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: AppButton(
                s.listHistory,
                icon: Icons.history,
                outlined: true,
                compact: true,
                onPressed: () async {
                  final id = await showDialog<int>(
                    context: context,
                    builder: (context) => AppDialog(
                      title: s.shoppingLists,
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(s.close),
                        ),
                      ],
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final candidate in state.lists)
                            ListTile(
                              title: Text(_label(candidate.name)),
                              leading: const Icon(Icons.list),
                              trailing: candidate.id == state.selected
                                  ? const Icon(Icons.check)
                                  : null,
                              onTap: () => Navigator.pop(context, candidate.id),
                            ),
                        ],
                      ),
                    ),
                  );
                  if (id != null && mounted) controller.select(id);
                },
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: AppButton(
                s.delete,
                icon: Icons.delete_outline,
                outlined: true,
                compact: true,
                onPressed: () async {
                  if (await confirmDelete(context) && mounted) {
                    controller.deleteCurrent();
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          border: AppColors.gold,
          child: Form(
            key: _form,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: s.newItem,
                        controller: _name,
                        validator: (value) => requiredText(context, value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _add,
                      tooltip: s.add,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: s.quantity,
                        controller: _quantity,
                        keyboard: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) => _number(value, quantity: true),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _unit,
                        decoration: InputDecoration(labelText: s.unit),
                        items: [
                          for (final unit in _units)
                            DropdownMenuItem(value: unit, child: Text(unit)),
                        ],
                        onChanged: (value) => _unit = value ?? _unit,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: AppTextField(
                        label: s.estimatedPrice,
                        controller: _price,
                        keyboard: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (visible.isEmpty) const AppEmptyState(),
        for (final item in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              border: item.purchased ? AppColors.line : AppColors.gold,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: item.purchased,
                    activeColor: AppColors.gold,
                    semanticLabel: s.purchased,
                    onChanged: (_) => controller.toggle(item),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _label(item.name),
                          style: TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w600,
                            decoration: item.purchased
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        Text(
                          '${item.quantity} ${item.unit} · ${euro(context, item.price)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    euro(context, item.quantity * item.price),
                    style: AppTypography.label(AppColors.ink, 10),
                  ),
                  IconButton(
                    tooltip: s.edit,
                    onPressed: () => _edit(item),
                    icon: const Icon(Icons.edit, size: 16),
                  ),
                  IconButton(
                    tooltip: s.delete,
                    onPressed: () async {
                      if (await confirmDelete(context) && mounted) {
                        controller.remove(item);
                      }
                    },
                    icon: const Icon(Icons.delete_outline, size: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _stat(
    String label,
    String value, {
    bool gold = false,
    VoidCallback? onTap,
  }) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: ColoredBox(
        color: gold ? AppColors.gold : AppColors.navy,
        child: SizedBox(
          height: 78,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label.toUpperCase(),
                textAlign: TextAlign.center,
                style: AppTypography.label(Colors.white, 8),
              ),
              const SizedBox(height: 7),
              FittedBox(
                child: Text(
                  value,
                  style: AppTypography.heading(19)
                      .copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
