import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/utils/date_utils.dart';

class TeamTasksPage extends ConsumerStatefulWidget {
  const TeamTasksPage({super.key});

  @override
  ConsumerState<TeamTasksPage> createState() => _TeamTasksPageState();
}

class _TeamTasksPageState extends ConsumerState<TeamTasksPage> {
  UserModel? _selectedUser;
  String _viewDate = todayStr();

  @override
  Widget build(BuildContext context) {
    final allUsersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      backgroundColor: AppTheme.paper,
      body: allUsersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allUsers) {
          final users = allUsers
              .where((u) => !u.isAdmin || u.email != 'admin@dailytracker.com')
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(
                  'Team\'s Tasks',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: DropdownButtonFormField<UserModel>(
                  value: _selectedUser,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  hint: const Text('Select a team member...'),
                  items: users.map((u) {
                    return DropdownMenuItem(
                      value: u,
                      child: Text('${u.displayName} (${u.email})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedUser = val;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final initialDate = DateTime.parse(_viewDate);
                          final d = await showDatePicker(
                            context: context,
                            initialDate: initialDate,
                            firstDate: DateTime(2023),
                            lastDate: DateTime(2050),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AppTheme.navy,
                                    onPrimary: Colors.white,
                                    onSurface: AppTheme.ink,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (d != null) {
                            setState(() {
                              _viewDate = d.toIso8601String().substring(0, 10);
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black45),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month,
                                  size: 20, color: AppTheme.ink),
                              const SizedBox(width: 12),
                              Text(
                                _viewDate,
                                style: const TextStyle(
                                    fontSize: 14, color: AppTheme.ink),
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_drop_down,
                                  color: AppTheme.inkSoft),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedUser != null)
                Expanded(
                  child: _ReadOnlyPlanner(
                      uid: _selectedUser!.uid, viewDate: _viewDate),
                )
              else
                const Expanded(
                  child: Center(
                    child: Text(
                      'Please select a user to view their tasks.',
                      style: TextStyle(color: AppTheme.inkSoft),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ReadOnlyPlanner extends ConsumerWidget {
  final String uid;
  final String viewDate;

  const _ReadOnlyPlanner({required this.uid, required this.viewDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allDataAsync = ref.watch(allDayDataProvider(uid));

    return allDataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (rawData) {
        final dailyData = rawData.map((k, v) => MapEntry(k, v as DayData));
        final dayData = dailyData[viewDate] ?? DayData.empty();

        final q1 = dayData.tasks.where((t) => t.quad == 'q1').toList();
        final q2 = dayData.tasks.where((t) => t.quad == 'q2').toList();
        final q3 = dayData.tasks.where((t) => t.quad == 'q3').toList();
        final q4 = dayData.tasks.where((t) => t.quad == 'q4').toList();
        final inbox = dayData.tasks.where((t) => t.quad == null).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Viewing tasks for $viewDate',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 16),
              // Inbox
              if (inbox.isNotEmpty) ...[
                const Text(
                  'Inbox',
                  style: TextStyle(
                    color: AppTheme.inkSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                for (final t in inbox) ...[
                  _ReadOnlyTaskCard(task: t),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 16),
              ],

              // Matrix
              const Text(
                'The Matrix',
                style: TextStyle(
                  color: AppTheme.inkSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  if (isMobile) {
                    return Column(
                      children: [
                        _ReadOnlyQuad(
                          title: 'Do First',
                          subtitle: 'Urgent + Important',
                          bg: AppTheme.doFirstBg,
                          titleColor: Colors.white,
                          titleBg: AppTheme.doFirst,
                          tasks: q1,
                        ),
                        const SizedBox(height: 16),
                        _ReadOnlyQuad(
                          title: 'Schedule',
                          subtitle: 'Not Urgent + Important',
                          bg: AppTheme.scheduleBg,
                          titleColor: Colors.white,
                          titleBg: AppTheme.schedule,
                          tasks: q2,
                        ),
                        const SizedBox(height: 16),
                        _ReadOnlyQuad(
                          title: 'Delegate',
                          subtitle: 'Urgent + Not Important',
                          bg: AppTheme.delegateBg,
                          titleColor: Colors.white,
                          titleBg: AppTheme.delegate,
                          tasks: q3,
                        ),
                        const SizedBox(height: 16),
                        _ReadOnlyQuad(
                          title: 'Drop / Later',
                          subtitle: 'Not Urgent + Not Important',
                          bg: AppTheme.dropBg,
                          titleColor: Colors.white,
                          titleBg: AppTheme.drop,
                          tasks: q4,
                        ),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _ReadOnlyQuad(
                              title: 'Do First',
                              subtitle: 'Urgent + Important',
                              bg: AppTheme.doFirstBg,
                              titleColor: Colors.white,
                              titleBg: AppTheme.doFirst,
                              tasks: q1,
                            ),
                            const SizedBox(height: 16),
                            _ReadOnlyQuad(
                              title: 'Delegate',
                              subtitle: 'Urgent + Not Important',
                              bg: AppTheme.delegateBg,
                              titleColor: Colors.white,
                              titleBg: AppTheme.delegate,
                              tasks: q3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _ReadOnlyQuad(
                              title: 'Schedule',
                              subtitle: 'Not Urgent + Important',
                              bg: AppTheme.scheduleBg,
                              titleColor: Colors.white,
                              titleBg: AppTheme.schedule,
                              tasks: q2,
                            ),
                            const SizedBox(height: 16),
                            _ReadOnlyQuad(
                              title: 'Drop / Later',
                              subtitle: 'Not Urgent + Not Important',
                              bg: AppTheme.dropBg,
                              titleColor: Colors.white,
                              titleBg: AppTheme.drop,
                              tasks: q4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),
              // Done Log
              ExpansionTile(
                title: Text(
                  'Done Log (${dayData.done.length})',
                  style: const TextStyle(
                    fontSize: 12,
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
                children: dayData.done.map((d) {
                  return ListTile(
                    title: Text(
                      d.text,
                      style: const TextStyle(
                        fontSize: 13,
                        decoration: TextDecoration.lineThrough,
                        color: AppTheme.inkSoft,
                      ),
                    ),
                    subtitle: d.description != null
                        ? Text(d.description!,
                            style: const TextStyle(fontSize: 11))
                        : null,
                    trailing: Text(
                      d.completedAt.substring(11, 16),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Backlog
              ExpansionTile(
                title: Text(
                  'Backlog Items (${dayData.backlog.length})',
                  style: const TextStyle(
                    fontSize: 12,
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
                children: dayData.backlog.map((b) {
                  return ListTile(
                    title: Text(
                      b.text,
                      style: const TextStyle(fontSize: 13, color: AppTheme.ink),
                    ),
                    subtitle: b.description != null
                        ? Text(b.description!,
                            style: const TextStyle(fontSize: 11))
                        : null,
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReadOnlyQuad extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color bg;
  final Color titleColor;
  final Color titleBg;
  final List<TaskModel> tasks;

  const _ReadOnlyQuad({
    required this.title,
    required this.subtitle,
    required this.bg,
    required this.titleColor,
    required this.titleBg,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.line.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // fill horizontally
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: titleBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: titleBg,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No tasks here',
                  style: TextStyle(
                      color: titleBg.withOpacity(0.4),
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
            )
          else
            for (final t in tasks)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ReadOnlyTaskCard(task: t),
              ),
        ],
      ),
    );
  }
}

class _ReadOnlyTaskCard extends StatelessWidget {
  final TaskModel task;
  const _ReadOnlyTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.line),
        boxShadow: const [
          BoxShadow(
              color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.text,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.ink,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              task.description!,
              style: const TextStyle(fontSize: 11, color: AppTheme.inkSoft),
            ),
          ],
        ],
      ),
    );
  }
}
