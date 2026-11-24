import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/design_system.dart';
import '../../../core/widgets/editor_dialog.dart';
import '../data/demo_calendar.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _month = DateTime(2026, 4);
  DateTime _selected = DateTime(2026, 4, 5);
  bool _dayExpanded = true;

  List<String> get _partners => ['Florian', 'Sophie', context.strings.both];

  String _title(String value) => switch (value) {
    '@groceries' => context.strings.organicGroceries,
    '@dinner' => context.strings.dinner,
    '@shopping' => context.strings.buyGroceries,
    _ => value,
  };

  Future<void> _edit({int? index, CalendarEvent? event}) async {
    final s = context.strings;
    final fields = await showEditor(
      context,
      event == null ? s.newEvent : s.edit,
      [
        editField(s.name, value: event == null ? '' : _title(event.title)),
        editField(
          s.date,
          value: editorDate(event?.date ?? _selected),
          input: EditorInput.date,
        ),
        editField(
          s.partner,
          value: _partners[event?.partner ?? 2],
          options: _partners,
          input: EditorInput.select,
        ),
        editField(
          s.details,
          value: event?.notes ?? '',
          input: EditorInput.notes,
        ),
      ],
    );
    if (fields == null || !mounted) return;
    final date = DateTime.parse(fields[1]);
    ref.read(eventsProvider.notifier).save((
      title: fields[0],
      date: date,
      partner: _partners.indexOf(fields[2]).clamp(0, 2),
      notes: fields[3],
    ), index: index);
    setState(() {
      _month = DateTime(date.year, date.month);
      _selected = date;
      _dayExpanded = true;
    });
  }

  void _move(int amount) => setState(() {
    _month = DateTime(_month.year, _month.month + amount);
    _selected = _month;
    _dayExpanded = false;
  });

  Future<void> _details(int index, CalendarEvent event) async {
    final s = context.strings;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AppDialog(
        title: s.eventDetails,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.close),
          ),
          AppButton(s.edit, onPressed: () => Navigator.pop(context, 'edit')),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_title(event.title), style: AppTypography.heading(20)),
            const SizedBox(height: 8),
            Text(
              DateFormat.yMMMMEEEEd(context.languageCode).format(event.date),
            ),
            Text(_partners[event.partner]),
            if (event.notes.isNotEmpty) Text(event.notes),
          ],
        ),
      ),
    );
    if (choice == 'edit' && mounted) await _edit(index: index, event: event);
  }

  Widget _row(int index, CalendarEvent event) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: AppCard(
      onTap: () => _details(index, event),
      child: Row(
        children: [
          const Icon(Icons.event, color: AppColors.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(event.title),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                AppLabel(
                  '${_partners[event.partner]} · ${DateFormat.Md(context.languageCode).format(event.date)}',
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.navy),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final dateFormat = DateFormat.E(context.languageCode);
    final events = ref.watch(eventsProvider).indexed.toList()
      ..sort((a, b) => a.$2.date.compareTo(b.$2.date));
    final start = DateTime(_month.year, _month.month, 2 - _month.weekday);
    final dateEvents = events
        .where((pair) => DateUtils.isSameDay(pair.$2.date, _selected))
        .toList();
    final upcoming = events.where((pair) => pair.$2.date.isAfter(_selected));
    return AppPage(
      children: [
        AppHeader(
          title: s.calendar,
          action: IconButton.filled(
            style: IconButton.styleFrom(backgroundColor: AppColors.gold),
            tooltip: s.newEvent,
            onPressed: () => _edit(),
            icon: const Icon(Icons.add),
          ),
        ),
        if (!_dayExpanded)
          AppCard(
            border: AppColors.gold,
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: s.previous,
                      onPressed: () => _move(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        DateFormat.yMMMM(context.languageCode).format(_month),
                        textAlign: TextAlign.center,
                        style: AppTypography.heading(19),
                      ),
                    ),
                    IconButton(
                      tooltip: s.next,
                      onPressed: () => _move(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Text(
                          dateFormat
                              .format(DateTime(2026, 4, 6 + i))
                              .toUpperCase(),
                          textAlign: TextAlign.center,
                          style: AppTypography.label(AppColors.muted, 8),
                        ),
                      ),
                  ],
                ),
                for (var row = 0; row < 6; row++)
                  Row(
                    children: [
                      for (var col = 0; col < 7; col++)
                        Expanded(
                          child: _day(
                            DateTime(
                              start.year,
                              start.month,
                              start.day + row * 7 + col,
                            ),
                            events,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        if (_dayExpanded)
          AppCard(
            color: AppColors.field,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: AppColors.line,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppLabel(
                            DateFormat.MMMMEEEEd(context.languageCode)
                                .format(_selected),
                          ),
                          AppLabel(
                            '${dateEvents.length} ${s.activities}',
                            color: AppColors.gold,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _dayExpanded = false),
                      child: Text(s.close),
                    ),
                  ],
                ),
                if (dateEvents.isEmpty)
                  const AppEmptyState(icon: Icons.event_available),
                for (final (index, event) in dateEvents) _row(index, event),
              ],
            ),
          ),
        const SizedBox(height: 24),
        AppLabel(s.upcoming, color: AppColors.muted),
        const SizedBox(height: 12),
        if (upcoming.isEmpty) AppEmptyState(message: s.noUpcoming),
        for (final (index, event) in upcoming) _row(index, event),
      ],
    );
  }

  Widget _day(DateTime day, List<(int, CalendarEvent)> events) {
    final selected = DateUtils.isSameDay(day, _selected);
    final marked = events.any((pair) => DateUtils.isSameDay(pair.$2.date, day));
    return Semantics(
      selected: selected,
      label: DateFormat.yMMMMd(context.languageCode).format(day),
      child: InkWell(
        onTap: () => setState(() {
          _selected = day;
          _month = DateTime(day.year, day.month);
          _dayExpanded = true;
        }),
        child: Container(
          height: 42,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : AppColors.paper,
            border: Border.all(
              color: selected ? AppColors.navy : AppColors.line,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : day.month == _month.month
                      ? AppColors.navy
                      : AppColors.muted,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (marked)
                const Icon(Icons.circle, size: 5, color: AppColors.gold),
            ],
          ),
        ),
      ),
    );
  }
}
