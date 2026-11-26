import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/demo_state.dart';

typedef CalendarEvent = ({
  String title,
  String notes,
  DateTime date,
  int partner,
});

final eventsProvider =
    NotifierProvider<DemoRecords<CalendarEvent>, List<CalendarEvent>>(
      () => DemoRecords(
        () => [
          (
            title: '@groceries',
            notes: '84.50 €',
            date: DateTime(2026, 4, 5),
            partner: 1,
          ),
          (title: '@dinner', notes: '', date: DateTime(2026, 4, 6), partner: 2),
          (
            title: '@shopping',
            notes: '',
            date: DateTime(2026, 4, 11),
            partner: 2,
          ),
        ],
      ),
    );
