import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/design_system.dart';
import '../../../core/widgets/editor_dialog.dart';
import '../data/demo_tasks.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  var _week = DateTime(2026, 4, 6);
  int _filter = 0;
  String? _area;

  String _label(String value) {
    final s = context.strings;
    return switch (value) {
      '@kitchen' => s.kitchen,
      '@living' => s.livingRoom,
      '@bedroom' => s.bedroom,
      '@bathroom' => s.bathroom,
      '@garden' => s.garden,
      '@clothes' => s.clothes,
      '@other' => s.other,
      '@breakfast' => s.breakfast,
      '@dinner' => s.dinner,
      '@laundry' => s.laundry,
      '@iron' => s.iron,
      '@mow' => s.mow,
      '@cleanBath' => s.cleanBath,
      '@buyGroceries' => s.buyGroceries,
      _ => value,
    };
  }

  List<String> get _partners => [
    'Florian',
    'Sophie',
    context.strings.demoCouple,
  ];

  Future<void> _edit(
    List<String> areas, {
    int? index,
    HouseholdTask? task,
  }) async {
    final s = context.strings;
    final translatedAreas = areas.map(_label).toList();
    final priority = [s.normal, s.high];
    final values = await showEditor(
      context,
      task == null ? s.newTask : s.edit,
      [
        editField(s.taskName, value: task == null ? '' : _label(task.name)),
        editField(
          s.rooms,
          value: _label(task?.room ?? _area ?? areas.first),
          input: EditorInput.select,
          options: translatedAreas,
        ),
        editField(
          s.partner,
          value: _partners[task?.partner ?? 0],
          input: EditorInput.select,
          options: _partners,
        ),
        editField(
          s.priority,
          value: task?.high == true ? s.high : s.normal,
          input: EditorInput.select,
          options: priority,
        ),
        editField(
          s.deadline,
          value: editorDate(task?.deadline ?? _week),
          input: EditorInput.date,
        ),
      ],
    );
    if (values == null || !mounted) return;
    final deadline = DateTime.parse(values[4]);
    ref.read(tasksProvider.notifier).save((
      name: values[0],
      room: areas[translatedAreas.indexOf(values[1])],
      partner: _partners.indexOf(values[2]).clamp(0, 2),
      high: values[3] == priority[1],
      deadline: deadline,
      complete: task?.complete ?? false,
    ), index: index);
    setState(() {
      _week = DateTime(
        deadline.year,
        deadline.month,
        deadline.day - deadline.weekday + 1,
      );
      _filter = 0;
      _area = null;
    });
  }

  void _moveWeek(int amount) => setState(() {
    _week = DateTime(_week.year, _week.month, _week.day + amount * 7);
  });

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final areas = ref.watch(areasProvider);
    final tasks = ref.watch(tasksProvider);
    final nextWeek = DateTime(_week.year, _week.month, _week.day + 7);
    final visible = tasks.indexed.where((pair) {
      final task = pair.$2;
      if (_area != null && task.room != _area) return false;
      return switch (_filter) {
        2 => !task.complete,
        3 => task.complete,
        _ => !task.deadline.isBefore(_week) && task.deadline.isBefore(nextWeek),
      };
    }).toList();
    final weekFormat = DateFormat.MMMd(context.languageCode);
    const areaIcons = [
      Icons.restaurant,
      Icons.chair,
      Icons.bed,
      Icons.bathtub,
      Icons.eco,
      Icons.checkroom,
      Icons.more_horiz,
    ];
    const areaColors = [
      Color(0xffff6a00),
      Color(0xff287bf1),
      Color(0xff5135e8),
      Color(0xff00a9c5),
      Color(0xff00b85a),
      Color(0xffed2f98),
      Color(0xff687487),
    ];
    return AppPage(
      children: [
        AppHeader(title: s.tasks),
        Row(
          children: [
            for (final (index, item) in [
              (s.week, Icons.calendar_today),
              (s.create, Icons.add),
              (s.pending, Icons.schedule),
              (s.completed, Icons.done_all),
            ].indexed) ...[
              if (index > 0) const SizedBox(width: 7),
              Expanded(
                child: AppButton(
                  item.$1,
                  icon: item.$2,
                  compact: true,
                  outlined: index != _filter,
                  onPressed: index == 1
                      ? () => _edit(areas)
                      : () => setState(() => _filter = index),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 19),
        AppCard(
          color: AppColors.field,
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              IconButton(
                tooltip: s.previous,
                onPressed: () => _moveWeek(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${s.weeklyRange} ${weekFormat.format(_week)} – ${weekFormat.format(nextWeek.subtract(const Duration(days: 1)))}'
                      .toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppTypography.label(),
                ),
              ),
              IconButton(
                tooltip: s.next,
                onPressed: () => _moveWeek(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        const SizedBox(height: 29),
        AppLabel(s.rooms, color: AppColors.muted),
        const SizedBox(height: 13),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 9,
            runSpacing: 10,
            children: [
              for (final (i, area) in areas.indexed)
                SizedBox(
                  width: (constraints.maxWidth - 27) / 4,
                  child: AppCard(
                    border: _area == area ? AppColors.gold : AppColors.line,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 12,
                    ),
                    onTap: () =>
                        setState(() => _area = _area == area ? null : area),
                    child: Column(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: areaColors[i.clamp(0, 6)],
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Icon(
                            areaIcons[i.clamp(0, 6)],
                            size: 17,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _label(area).toUpperCase(),
                          textAlign: TextAlign.center,
                          style: AppTypography.label(
                            AppColors.muted,
                            7,
                          ).copyWith(letterSpacing: 0),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppButton(
          '${s.addRoom} +',
          outlined: true,
          onPressed: () async {
            final result = await showEditor(context, s.addRoom, [
              editField(s.name),
            ]);
            if (result != null &&
                mounted &&
                !areas.map(_label).contains(result[0])) {
              ref.read(areasProvider.notifier).save(result[0]);
            }
          },
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: AppLabel(
                _filter == 0
                    ? s.weeklyTasks
                    : _filter == 2
                    ? s.pending
                    : s.completed,
                color: AppColors.muted,
              ),
            ),
            AppLabel('${visible.length}', color: AppColors.gold),
          ],
        ),
        const SizedBox(height: 11),
        if (visible.isEmpty) const AppEmptyState(),
        for (final (index, task) in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              child: Row(
                children: [
                  Checkbox(
                    value: task.complete,
                    onChanged: (value) =>
                        ref.read(tasksProvider.notifier).save((
                          name: task.name,
                          room: task.room,
                          partner: task.partner,
                          high: task.high,
                          deadline: task.deadline,
                          complete: value ?? false,
                        ), index: index),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _label(task.name),
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppLabel(
                          _partners[task.partner],
                          color: AppColors.gold,
                        ),
                        Text(
                          '${_label(task.room)} · ${DateFormat.Md(context.languageCode).format(task.deadline)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                        if (task.high)
                          AppLabel(s.high, color: AppColors.danger),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: s.edit,
                    onPressed: () => _edit(areas, index: index, task: task),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
