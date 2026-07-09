import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/utils/date_utils.dart';
import '../../shared/utils/rollover.dart' as rollover_util;
import '../../shared/widgets/toast_widget.dart';

class PlannerPage extends ConsumerStatefulWidget {
  const PlannerPage({super.key});

  @override
  ConsumerState<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends ConsumerState<PlannerPage> {
  bool _didRollover = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    if (user == null) return const SizedBox.shrink();

    final allDataAsync = ref.watch(allDayDataProvider(user.uid));

    return allDataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (rawData) {
        final dailyData = rawData.map((k, v) => MapEntry(k, v as DayData));

        // Perform rollover once
        if (!_didRollover) {
          _didRollover = true;
          final today = todayStr();
          final rolledData = rollover_util.rolloverTasks(dailyData, today);
          if (rolledData[today]?.lastRolloverDate == today &&
              dailyData[today]?.lastRolloverDate != today) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await ref
                  .read(dataServiceProvider)
                  .saveDayData(user.uid, today, rolledData[today]!);
            });
          }
        }

        return _PlannerContent(uid: user.uid, allData: dailyData);
      },
    );
  }
}

class _PlannerContent extends ConsumerStatefulWidget {
  final String uid;
  final Map<String, DayData> allData;
  const _PlannerContent({required this.uid, required this.allData});

  @override
  ConsumerState<_PlannerContent> createState() => _PlannerContentState();
}

class _PlannerContentState extends ConsumerState<_PlannerContent> {
  final _taskInputCtrl = TextEditingController();
  final _descInputCtrl = TextEditingController();
  bool _showCalendar = false;
  DateTime _calendarMonth = DateTime.now();

  @override
  void dispose() {
    _taskInputCtrl.dispose();
    _descInputCtrl.dispose();
    super.dispose();
  }

  String get _selectedDate => ref.read(selectedDateProvider);
  DayData get _dayData => widget.allData[_selectedDate] ?? DayData.empty();

  Future<void> _save(DayData data) async {
    await ref
        .read(dataServiceProvider)
        .saveDayData(widget.uid, _selectedDate, data);
  }

  String _uid(String prefix) =>
      '$prefix${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}${(1000 + (DateTime.now().microsecond % 9000)).toString()}';

  Future<void> _addTask() async {
    final text = _taskInputCtrl.text.trim();
    final desc = _descInputCtrl.text.trim();
    if (text.isEmpty) return;
    final task = TaskModel(
        id: _uid('t'),
        text: text,
        description: desc.isNotEmpty ? desc : null,
        day: _selectedDate);
    final updated = _dayData.copyWith(tasks: [..._dayData.tasks, task]);
    _taskInputCtrl.clear();
    _descInputCtrl.clear();
    await _save(updated);
  }

  Future<void> _moveTaskToQuad(TaskModel task, String? quad) async {
    final tasks = _dayData.tasks.map((t) {
      if (t.id == task.id) {
        return TaskModel(
          id: t.id,
          text: t.text,
          quad: quad,
          day: t.day,
          carried: t.carried,
          description: t.description,
        );
      }
      return t;
    }).toList();
    await _save(_dayData.copyWith(tasks: tasks));
  }

  Future<void> _deleteTask(String id) async {
    final tasks = _dayData.tasks.where((t) => t.id != id).toList();
    await _save(_dayData.copyWith(tasks: tasks));
  }

  Future<void> _markDone(TaskModel task) async {
    final done = DoneItem(
      id: task.id,
      text: task.text,
      quad: task.quad,
      date: _selectedDate,
      description: task.description,
      completedAt: DateTime.now().toIso8601String(),
    );
    final tasks = _dayData.tasks.where((t) => t.id != task.id).toList();
    await _save(
      _dayData.copyWith(tasks: tasks, done: [..._dayData.done, done]),
    );
    ToastWidget.show(context, '✓ Task marked complete!');
  }

  Future<void> _reopenDone(DoneItem item) async {
    final task = TaskModel(
      id: item.id,
      text: item.text,
      quad: item.quad,
      day: _selectedDate,
      description: item.description,
    );
    final done = _dayData.done.where((d) => d.id != item.id).toList();
    await _save(
      _dayData.copyWith(tasks: [..._dayData.tasks, task], done: done),
    );
  }

  Future<void> _reopenBacklog(TaskModel item) async {
    final task = TaskModel(
      id: item.id,
      text: item.text,
      quad: item.quad,
      day: _selectedDate,
      description: item.description,
    );
    final backlog = _dayData.backlog.where((b) => b.id != item.id).toList();
    await _save(
      _dayData.copyWith(tasks: [..._dayData.tasks, task], backlog: backlog),
    );
  }

  void _showSixPMReview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewSheet(
        activeTasks: _dayData.tasks,
        doneTasks: _dayData.done,
        onCommit: (checkedIds, uncheckedIds) async {
          Navigator.pop(context);
          final newDone = <DoneItem>[];
          final newBacklog = List<TaskModel>.from(_dayData.backlog);

          for (final id in checkedIds) {
            final asDone = _dayData.done.where((d) => d.id == id).firstOrNull;
            if (asDone != null) {
              newDone.add(asDone);
              continue;
            }
            final asTask = _dayData.tasks.where((t) => t.id == id).firstOrNull;
            if (asTask != null) {
              newDone.add(DoneItem(
                  id: asTask.id,
                  text: asTask.text,
                  quad: asTask.quad,
                  description: asTask.description,
                  date: _selectedDate,
                  completedAt: DateTime.now().toIso8601String()));
            }
          }

          for (final id in uncheckedIds) {
            final asTask = _dayData.tasks.where((t) => t.id == id).firstOrNull;
            if (asTask != null) {
              newBacklog.add(asTask);
              continue;
            }
            final asDone = _dayData.done.where((d) => d.id == id).firstOrNull;
            if (asDone != null) {
              newBacklog.add(TaskModel(
                  id: asDone.id,
                  text: asDone.text,
                  quad: asDone.quad,
                  description: asDone.description,
                  day: _selectedDate));
            }
          }

          await _save(_dayData.copyWith(
            tasks: [],
            done: newDone,
            backlog: newBacklog,
            lastReviewDate: todayStr(),
          ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final today = todayStr();
    final isHistorical = selectedDate != today;
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > 900;

    final allTasks = _dayData.tasks;
    final inboxTasks = allTasks.where((t) => t.quad == null).toList();
    final q1 = allTasks.where((t) => t.quad == 'q1').toList();
    final q2 = allTasks.where((t) => t.quad == 'q2').toList();
    final q3 = allTasks.where((t) => t.quad == 'q3').toList();
    final q4 = allTasks.where((t) => t.quad == 'q4').toList();

    final isPastSixPM = DateTime.now().hour >= 18;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return SingleChildScrollView(
      padding:
          EdgeInsets.fromLTRB(isMobile ? 12 : 24, 24, isMobile ? 12 : 24, 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Date Navigation Bar ──────────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.line),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Prev button
                    _DateNavBtn(
                      icon: Icons.chevron_left,
                      onTap: () {
                        ref.read(selectedDateProvider.notifier).state =
                            adjustDateStr(selectedDate, -1);
                      },
                    ),
                    const SizedBox(width: 8),

                    // Date display + calendar
                    GestureDetector(
                      onTap: () => setState(() {
                        _showCalendar = !_showCalendar;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.line),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                          color: Colors.white,
                        ),
                        child: Text(
                          formatDateLabel(selectedDate),
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppTheme.navy,
                                    fontSize: 13,
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Next button
                    _DateNavBtn(
                      icon: Icons.chevron_right,
                      onTap: () {
                        ref.read(selectedDateProvider.notifier).state =
                            adjustDateStr(selectedDate, 1);
                      },
                    ),
                  ],
                ),
                const SizedBox(width: 4),

                // Today button
                TextButton(
                  onPressed: () =>
                      ref.read(selectedDateProvider.notifier).state = today,
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.primaryBg,
                    foregroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                  ),
                  child: const Text(
                    'Today',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                if (isHistorical)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      border: Border.all(
                        color: Color(0xFFD97706).withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Historical View',
                      style: TextStyle(
                        color: Color(0xFFD97706),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Calendar dropdown
          if (_showCalendar)
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _CalendarWidget(
                  displayMonth: _calendarMonth,
                  selectedDate: selectedDate,
                  allData: widget.allData,
                  onSelectDate: (d) {
                    ref.read(selectedDateProvider.notifier).state = d;
                    setState(() {
                      _showCalendar = false;
                    });
                  },
                  onMonthChange: (m) => setState(() {
                    _calendarMonth = m;
                  }),
                ),
              ),
            ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.05, end: 0),

          const SizedBox(height: 16),

          // ── Stats Banner ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.navy,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHistorical
                            ? 'Historical: ${formatDateLabel(selectedDate)}'
                            : 'Daily Matrix',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 20,
                        children: [
                          _StatChip(label: '${allTasks.length} open'),
                          _StatChip(
                            label: '${_dayData.done.length} done today',
                          ),
                          _StatChip(
                            label:
                                '${allTasks.where((t) => t.carried > 0).length} carried',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isHistorical)
                  ElevatedButton.icon(
                    onPressed: _showSixPMReview,
                    icon: isPastSixPM
                        ? const Icon(Icons.notifications_active, size: 16)
                        : const Icon(Icons.done_all, size: 16),
                    label: const Text('6 PM Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.navy,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Main Two-column Layout ────────────────────────────────────────────
          isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 320,
                      child: _InboxPanel(
                        tasks: inboxTasks,
                        inputCtrl: _taskInputCtrl,
                        descInputCtrl: _descInputCtrl,
                        onAdd: _addTask,
                        onDelete: _deleteTask,
                        onMoveToQuad: _moveTaskToQuad,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _MatrixPanel(
                        q1: q1,
                        q2: q2,
                        q3: q3,
                        q4: q4,
                        onMoveToQuad: _moveTaskToQuad,
                        onDelete: _deleteTask,
                        onMarkDone: _markDone,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _InboxPanel(
                      tasks: inboxTasks,
                      inputCtrl: _taskInputCtrl,
                      descInputCtrl: _descInputCtrl,
                      onAdd: _addTask,
                      onDelete: _deleteTask,
                      onMoveToQuad: _moveTaskToQuad,
                    ),
                    const SizedBox(height: 16),
                    _MatrixPanel(
                      q1: q1,
                      q2: q2,
                      q3: q3,
                      q4: q4,
                      onMoveToQuad: _moveTaskToQuad,
                      onDelete: _deleteTask,
                      onMarkDone: _markDone,
                    ),
                  ],
                ),

          const SizedBox(height: 20),

          // ── Done Log ─────────────────────────────────────────────────────────
          if (_dayData.done.isNotEmpty)
            _DoneLogPanel(
              done: _dayData.done,
              onReopen: _reopenDone,
            ),

          if (_dayData.backlog.isNotEmpty)
            _BacklogPanel(
              backlog: _dayData.backlog,
              onReopen: _reopenBacklog,
            ),
        ],
      ).animate().fadeIn(duration: 250.ms),
    );
  }
}

// ── Date Nav Button ──────────────────────────────────────────────────────────

class _DateNavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _DateNavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.line),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            color: Colors.white,
          ),
          child: Icon(icon, size: 18, color: AppTheme.inkSoft),
        ),
      );
}

class _StatChip extends StatelessWidget {
  final String label;
  const _StatChip({required this.label});

  @override
  Widget build(BuildContext context) =>
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13));
}

// ── Inbox Panel ───────────────────────────────────────────────────────────────

class _InboxPanel extends StatelessWidget {
  final List<TaskModel> tasks;
  final TextEditingController inputCtrl;
  final TextEditingController descInputCtrl;
  final VoidCallback onAdd;
  final void Function(String) onDelete;
  final void Function(TaskModel, String?) onMoveToQuad;

  const _InboxPanel({
    required this.tasks,
    required this.inputCtrl,
    required this.descInputCtrl,
    required this.onAdd,
    required this.onDelete,
    required this.onMoveToQuad,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "TODAY'S LIST",
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 11,
                    letterSpacing: 0.12,
                    color: AppTheme.inkSoft,
                  ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                        controller: inputCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Add a task or meeting…',
                        ),
                        maxLength: 140,
                        buildCounter: (
                          _, {
                          required currentLength,
                          required isFocused,
                          required maxLength,
                        }) =>
                            null,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descInputCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Add a description (optional)…',
                        ),
                        onSubmitted: (_) => onAdd(),
                        maxLines: 2,
                        minLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: onAdd, child: const Text('Add')),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'List everything first, then drag each one into the matrix or tap to place it.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.inkSoft),
            ),
            const SizedBox(height: 12),
            if (tasks.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.line,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Text(
                  'Your inbox is empty.\nAdd tasks above to start planning.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...tasks.asMap().entries.map((e) {
                final i = e.key;
                final task = e.value;
                return _TaskCard(
                  task: task,
                  number: i + 1,
                  onDelete: () => onDelete(task.id),
                  onTap: () => _showQuadPicker(context, task, onMoveToQuad),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _showQuadPicker(
    BuildContext context,
    TaskModel task,
    void Function(TaskModel, String?) move,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Description:',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppTheme.inkSoft),
              ),
              const SizedBox(height: 4),
              Text(
                task.description!,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.ink,
                    fontWeight: FontWeight.normal),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Place task in:',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: AppTheme.inkSoft),
            ),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select a quadrant:',
                style: TextStyle(color: AppTheme.inkSoft, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  SizedBox(
                    width: 130,
                    height: 50,
                    child: _QuadPickBtn('Do First', AppTheme.doFirst, () {
                      Navigator.pop(dialogCtx);
                      move(task, 'q1');
                    }),
                  ),
                  SizedBox(
                    width: 130,
                    height: 50,
                    child: _QuadPickBtn('Schedule', AppTheme.schedule, () {
                      Navigator.pop(dialogCtx);
                      move(task, 'q2');
                    }),
                  ),
                  SizedBox(
                    width: 130,
                    height: 50,
                    child: _QuadPickBtn('Delegate', AppTheme.delegate, () {
                      Navigator.pop(dialogCtx);
                      move(task, 'q3');
                    }),
                  ),
                  SizedBox(
                    width: 130,
                    height: 50,
                    child: _QuadPickBtn('Drop/Later', AppTheme.drop, () {
                      Navigator.pop(dialogCtx);
                      move(task, 'q4');
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  move(task, null);
                },
                child: const Text('Keep in Inbox'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuadPickBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuadPickBtn(this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

// ── Task Card ──────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final int? number;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _TaskCard({
    required this.task,
    this.number,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            if (number != null)
              Text(
                '$number.',
                style: TextStyle(
                  color: AppTheme.inkSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (number != null) const SizedBox(width: 8),
            const Icon(Icons.drag_handle, color: Color(0xFFCBD5E1), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.text,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (task.carried > 0) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.delegateBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '↻ ${task.carried}d carried',
                        style: const TextStyle(
                          color: AppTheme.delegate,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: AppTheme.inkSoft),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Matrix Panel ──────────────────────────────────────────────────────────────

class _MatrixPanel extends StatelessWidget {
  final List<TaskModel> q1, q2, q3, q4;
  final void Function(TaskModel, String?) onMoveToQuad;
  final void Function(String) onDelete;
  final void Function(TaskModel) onMarkDone;

  const _MatrixPanel({
    required this.q1,
    required this.q2,
    required this.q3,
    required this.q4,
    required this.onMoveToQuad,
    required this.onDelete,
    required this.onMarkDone,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'THE MATRIX',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 11,
                    letterSpacing: 0.12,
                    color: AppTheme.inkSoft,
                  ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _QuadrantDropZone(
                  quadId: 'q1',
                  title: 'Do First',
                  subtitle: 'Urgent + Important',
                  color: AppTheme.doFirst,
                  bgColor: AppTheme.doFirstBg,
                  tasks: q1,
                  onMoveToQuad: onMoveToQuad,
                  onDelete: onDelete,
                  onMarkDone: onMarkDone,
                ),
                _QuadrantDropZone(
                  quadId: 'q2',
                  title: 'Schedule',
                  subtitle: 'Not Urgent + Important',
                  color: AppTheme.schedule,
                  bgColor: AppTheme.scheduleBg,
                  tasks: q2,
                  onMoveToQuad: onMoveToQuad,
                  onDelete: onDelete,
                  onMarkDone: onMarkDone,
                ),
                _QuadrantDropZone(
                  quadId: 'q3',
                  title: 'Delegate',
                  subtitle: 'Urgent + Not Important',
                  color: AppTheme.delegate,
                  bgColor: AppTheme.delegateBg,
                  tasks: q3,
                  onMoveToQuad: onMoveToQuad,
                  onDelete: onDelete,
                  onMarkDone: onMarkDone,
                ),
                _QuadrantDropZone(
                  quadId: 'q4',
                  title: 'Drop / Later',
                  subtitle: 'Not Urgent + Not Important',
                  color: AppTheme.drop,
                  bgColor: AppTheme.dropBg,
                  tasks: q4,
                  onMoveToQuad: onMoveToQuad,
                  onDelete: onDelete,
                  onMarkDone: onMarkDone,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuadrantDropZone extends StatefulWidget {
  final String quadId, title, subtitle;
  final Color color, bgColor;
  final List<TaskModel> tasks;
  final void Function(TaskModel, String?) onMoveToQuad;
  final void Function(String) onDelete;
  final void Function(TaskModel) onMarkDone;

  const _QuadrantDropZone({
    required this.quadId,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.tasks,
    required this.onMoveToQuad,
    required this.onDelete,
    required this.onMarkDone,
  });

  @override
  State<_QuadrantDropZone> createState() => _QuadrantDropZoneState();
}

class _QuadrantDropZoneState extends State<_QuadrantDropZone> {
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<TaskModel>(
      onWillAcceptWithDetails: (d) {
        setState(() => _isDragOver = true);
        return true;
      },
      onLeave: (_) => setState(() => _isDragOver = false),
      onAcceptWithDetails: (detail) {
        setState(() => _isDragOver = false);
        widget.onMoveToQuad(detail.data, widget.quadId);
      },
      builder: (_, candidateData, __) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isDragOver ? widget.color.withOpacity(0.1) : widget.bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: _isDragOver ? widget.color : AppTheme.line.withOpacity(0.6),
            width: _isDragOver ? 2 : 1,
            style: _isDragOver ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              widget.subtitle,
              style: TextStyle(
                color: widget.color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.tasks.isEmpty)
              Center(
                child: Text(
                  'Drop tasks here',
                  style: TextStyle(
                    color: widget.color.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              )
            else
              ...widget.tasks.map(
                (t) => Draggable<TaskModel>(
                  data: t,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 200,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 8),
                        ],
                      ),
                      child: Text(t.text, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _QuadTaskItem(
                      task: t,
                      color: widget.color,
                      onDelete: () => widget.onDelete(t.id),
                      onDone: () => widget.onMarkDone(t),
                      onMoveToQuad: widget.onMoveToQuad,
                    ),
                  ),
                  child: _QuadTaskItem(
                    task: t,
                    color: widget.color,
                    onDelete: () => widget.onDelete(t.id),
                    onDone: () => widget.onMarkDone(t),
                    onMoveToQuad: widget.onMoveToQuad,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuadTaskItem extends StatelessWidget {
  final TaskModel task;
  final Color color;
  final VoidCallback onDelete, onDone;
  final void Function(TaskModel, String?) onMoveToQuad;

  const _QuadTaskItem({
    required this.task,
    required this.color,
    required this.onDelete,
    required this.onDone,
    required this.onMoveToQuad,
  });

  void _showMatrixDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Description:',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppTheme.inkSoft),
              ),
              const SizedBox(height: 4),
              Text(
                task.description!,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.ink,
                    fontWeight: FontWeight.normal),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              onMoveToQuad(task, null);
            },
            child: const Text('Move to Inbox'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMatrixDetails(context),
      onLongPress: onDone,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onDone,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Icon(Icons.check, size: 10, color: color),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                task.text,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.ink,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.close, size: 14, color: AppTheme.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Calendar Widget ───────────────────────────────────────────────────────────

class _CalendarWidget extends StatelessWidget {
  final DateTime displayMonth;
  final String selectedDate;
  final Map<String, DayData> allData;
  final void Function(String) onSelectDate;
  final void Function(DateTime) onMonthChange;

  const _CalendarWidget({
    required this.displayMonth,
    required this.selectedDate,
    required this.allData,
    required this.onSelectDate,
    required this.onMonthChange,
  });

  @override
  Widget build(BuildContext context) {
    final year = displayMonth.year;
    final month = displayMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startOffset = firstDay.weekday % 7;
    final today = todayStr();

    return SizedBox(
      width: 280,
      child: Column(
        children: [
          // Month header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: () {
                  onMonthChange(
                    DateTime(displayMonth.year, displayMonth.month - 1),
                  );
                },
              ),
              Expanded(
                child: Text(
                  '${_monthName(month)} $year',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppTheme.navy),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: () {
                  onMonthChange(
                    DateTime(displayMonth.year, displayMonth.month + 1),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Weekday headers
          Row(
            children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.inkSoft,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          // Days grid
          Wrap(
            spacing: 0,
            runSpacing: 4,
            children: [
              ...List.generate(
                startOffset,
                (_) => const SizedBox(width: 40, height: 32),
              ),
              ...List.generate(daysInMonth, (i) {
                final day = i + 1;
                final dateStr =
                    '${year}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                final isSelected = dateStr == selectedDate;
                final isToday = dateStr == today;
                final hasData = allData.containsKey(dateStr) &&
                    ((allData[dateStr]!.tasks.isNotEmpty) ||
                        (allData[dateStr]!.done.isNotEmpty));

                return GestureDetector(
                  onTap: () => onSelectDate(dateStr),
                  child: Container(
                    width: 40,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: isToday && !isSelected
                          ? Border.all(color: AppTheme.primary)
                          : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isToday ? AppTheme.primary : AppTheme.ink),
                          ),
                        ),
                        if (hasData)
                          Positioned(
                            bottom: 3,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white70
                                    : AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  String _monthName(int m) => [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][m - 1];
}

class _ReviewItem {
  final String id;
  final String text;
  final bool initiallyDone;
  _ReviewItem(this.id, this.text, this.initiallyDone);
}

class _ReviewSheet extends StatefulWidget {
  final List<TaskModel> activeTasks;
  final List<DoneItem> doneTasks;
  final void Function(Set<String> checkedIds, Set<String> uncheckedIds)
      onCommit;

  const _ReviewSheet({
    required this.activeTasks,
    required this.doneTasks,
    required this.onCommit,
  });

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  late final List<_ReviewItem> _items;
  final _checkedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _items = [
      ...widget.doneTasks.map((d) => _ReviewItem(d.id, d.text, true)),
      ...widget.activeTasks.map((t) => _ReviewItem(t.id, t.text, false)),
    ];
    for (final item in _items) {
      if (item.initiallyDone) _checkedIds.add(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌅', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '6 PM Review',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    'Which tasks did you finish today?',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.inkSoft),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '🎉 Nothing left to review. Great day!',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView(
                shrinkWrap: true,
                children: _items.map((t) {
                  final checked = _checkedIds.contains(t.id);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (checked)
                        _checkedIds.remove(t.id);
                      else
                        _checkedIds.add(t.id);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: checked ? const Color(0xFFF0FDF4) : Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(
                          color:
                              checked ? const Color(0xFFBBF7D0) : AppTheme.line,
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: checked,
                            onChanged: (_) => setState(() {
                              if (checked)
                                _checkedIds.remove(t.id);
                              else
                                _checkedIds.add(t.id);
                            }),
                            activeColor: AppTheme.navy,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.text,
                              style: TextStyle(
                                decoration:
                                    checked ? TextDecoration.lineThrough : null,
                                color: checked
                                    ? const Color(0xFF166534)
                                    : AppTheme.ink,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final uncheckedIds = _items
                        .map((i) => i.id)
                        .where((id) => !_checkedIds.contains(id))
                        .toSet();
                    widget.onCommit(_checkedIds, uncheckedIds);
                  },
                  child: const Text('Close Day & Save'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Later'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Completed tasks move to the Done log. Remaining tasks move to Backlog.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.inkSoft),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: MediaQuery.viewInsetsOf(context).bottom),
        ],
      ),
    );
  }
}

// ── Done Log Panel ──────────────────────────────────────────────────────────

class _DoneLogPanel extends StatelessWidget {
  final List<DoneItem> done;
  final void Function(DoneItem) onReopen;

  const _DoneLogPanel({
    required this.done,
    required this.onReopen,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'Done Log (${done.length})',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 11,
              letterSpacing: 0.12,
              color: AppTheme.inkSoft,
            ),
      ),
      collapsedBackgroundColor: AppTheme.card,
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: const BorderSide(color: AppTheme.line),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: const BorderSide(color: AppTheme.line),
      ),
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: done.length,
          itemBuilder: (_, i) {
            final d = done[i];
            return InkWell(
              onTap: () =>
                  _showTaskDetailsDialog(context, d.text, d.description),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        d.completedAt.substring(11, 16),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        d.text,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppTheme.ink,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onReopen(d),
                      icon: const Icon(Icons.undo, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 16,
                      color: AppTheme.inkSoft,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── Backlog Panel ────────────────────────────────────────────────────────────

class _BacklogPanel extends StatelessWidget {
  final List<TaskModel> backlog;
  final void Function(TaskModel) onReopen;

  const _BacklogPanel({
    required this.backlog,
    required this.onReopen,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'Backlog Items (${backlog.length})',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 11,
              letterSpacing: 0.12,
              color: AppTheme.inkSoft,
            ),
      ),
      collapsedBackgroundColor: AppTheme.card,
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: const BorderSide(color: AppTheme.line),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: const BorderSide(color: AppTheme.line),
      ),
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: backlog.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: AppTheme.line),
          itemBuilder: (_, i) {
            final b = backlog[i];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () =>
                  _showTaskDetailsDialog(context, b.text, b.description),
              title: Text(
                b.text,
                style: const TextStyle(fontSize: 13, color: AppTheme.ink),
              ),
              subtitle: b.description != null && b.description!.isNotEmpty
                  ? Text(
                      b.description!,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.inkSoft),
                    )
                  : null,
              trailing: IconButton(
                icon: const Icon(Icons.undo, size: 16),
                tooltip: 'Move back to Active Tasks',
                onPressed: () => onReopen(b),
              ),
            );
          },
        ),
      ],
    );
  }
}

void _showTaskDetailsDialog(
    BuildContext context, String title, String? description) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.ink,
        ),
      ),
      content: SingleChildScrollView(
        child: Text(
          description?.isNotEmpty == true
              ? description!
              : 'No description provided for this task.',
          style: const TextStyle(fontSize: 14, color: AppTheme.inkSoft),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
