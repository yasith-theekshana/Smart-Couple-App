import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/demo_state.dart';

typedef HouseholdTask = ({
  String name,
  String room,
  int partner,
  bool high,
  DateTime deadline,
  bool complete,
});

final tasksProvider =
    NotifierProvider<DemoRecords<HouseholdTask>, List<HouseholdTask>>(
      () => DemoRecords(
        () => [
          (
            name: '@breakfast',
            room: '@kitchen',
            partner: 0,
            high: false,
            deadline: DateTime(2026, 4, 6),
            complete: false,
          ),
          (
            name: '@dinner',
            room: '@kitchen',
            partner: 1,
            high: false,
            deadline: DateTime(2026, 4, 6),
            complete: false,
          ),
          (
            name: '@laundry',
            room: '@clothes',
            partner: 0,
            high: false,
            deadline: DateTime(2026, 4, 7),
            complete: true,
          ),
          (
            name: '@iron',
            room: '@clothes',
            partner: 1,
            high: false,
            deadline: DateTime(2026, 4, 8),
            complete: true,
          ),
          (
            name: '@mow',
            room: '@garden',
            partner: 0,
            high: false,
            deadline: DateTime(2026, 4, 11),
            complete: false,
          ),
          (
            name: '@cleanBath',
            room: '@bathroom',
            partner: 1,
            high: true,
            deadline: DateTime(2026, 4, 11),
            complete: false,
          ),
          (
            name: '@buyGroceries',
            room: '@other',
            partner: 2,
            high: false,
            deadline: DateTime(2026, 4, 11),
            complete: false,
          ),
        ],
      ),
    );
final areasProvider = NotifierProvider<DemoRecords<String>, List<String>>(
  () => DemoRecords(
    () => [
      '@kitchen',
      '@living',
      '@bedroom',
      '@bathroom',
      '@garden',
      '@clothes',
      '@other',
    ],
  ),
);
