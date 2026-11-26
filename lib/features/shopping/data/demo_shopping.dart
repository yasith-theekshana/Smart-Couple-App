import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef ShoppingItem = ({
  int id,
  String name,
  double quantity,
  String unit,
  double price,
  bool purchased,
});

typedef ShoppingList = ({int id, String name, List<ShoppingItem> items});
typedef ShoppingState = ({List<ShoppingList> lists, int selected});

final shoppingProvider = NotifierProvider<DemoShopping, ShoppingState>(
  DemoShopping.new,
);

class DemoShopping extends Notifier<ShoppingState> {
  int _nextId = 10;

  @override
  ShoppingState build() => (
    selected: 0,
    lists: [
      (
        id: 0,
        name: '@main',
        items: [
          (
            id: 1,
            name: '@bread',
            quantity: 2.0,
            unit: 'u',
            price: 1.20,
            purchased: false,
          ),
          (
            id: 2,
            name: '@milk',
            quantity: 1.0,
            unit: 'L',
            price: .95,
            purchased: true,
          ),
          (
            id: 3,
            name: '@detergent',
            quantity: 1.0,
            unit: 'u',
            price: 12.50,
            purchased: false,
          ),
          (
            id: 4,
            name: '@apples',
            quantity: 1.5,
            unit: 'kg',
            price: 2.40,
            purchased: false,
          ),
        ],
      ),
      (id: 5, name: '18/05/2026', items: const []),
      (id: 6, name: '11/05/2026', items: const []),
    ],
  );

  ShoppingList get _current =>
      state.lists.firstWhere((list) => list.id == state.selected);

  void select(int id) => state = (lists: state.lists, selected: id);

  void create(String name) {
    final id = _nextId++;
    state = (
      selected: id,
      lists: [...state.lists, (id: id, name: name, items: const [])],
    );
  }

  void deleteCurrent() {
    final remaining = state.lists
        .where((list) => list.id != state.selected)
        .toList();
    if (remaining.isEmpty) {
      remaining.add((id: _nextId++, name: '@main', items: const []));
    }
    state = (lists: remaining, selected: remaining.first.id);
  }

  void save({
    ShoppingItem? existing,
    required String name,
    required double quantity,
    required String unit,
    required double price,
  }) {
    final item = (
      id: existing?.id ?? _nextId++,
      name: name,
      quantity: quantity,
      unit: unit,
      price: price,
      purchased: existing?.purchased ?? false,
    );
    final items = _current.items;
    _replaceItems(
      existing == null
          ? [...items, item]
          : [
              for (final entry in items)
                if (entry.id == item.id) item else entry,
            ],
    );
  }

  void toggle(ShoppingItem item) => _replaceItems([
    for (final entry in _current.items)
      if (entry.id == item.id)
        (
          id: item.id,
          name: item.name,
          quantity: item.quantity,
          unit: item.unit,
          price: item.price,
          purchased: !item.purchased,
        )
      else
        entry,
  ]);

  void remove(ShoppingItem item) => _replaceItems(
    _current.items.where((entry) => entry.id != item.id).toList(),
  );

  void _replaceItems(List<ShoppingItem> items) => state = (
    selected: state.selected,
    lists: [
      for (final list in state.lists)
        if (list.id == state.selected)
          (id: list.id, name: list.name, items: items)
        else
          list,
    ],
  );
}
