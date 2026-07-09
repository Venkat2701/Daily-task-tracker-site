import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/utils/dashboard_calcs.dart';
import '../../shared/utils/date_utils.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    if (user == null) return const SizedBox.shrink();

    final allDataAsync = ref.watch(allDayDataProvider(user.uid));

    return allDataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (rawData) {
        final dailyData = rawData.map((k, v) => MapEntry(k, v as DayData));
        return _DashboardContent(dailyData: dailyData);
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final Map<String, DayData> dailyData;
  const _DashboardContent({required this.dailyData});

  @override
  Widget build(BuildContext context) {
    final today = todayStr();
    final dayData = dailyData[today] ?? DayData.empty();
    final percent = completionPercent(dayData);
    final streak = calculateStreak(dailyData);
    final qCounts = getQuadrantCounts(dailyData);
    final qTotal = qCounts.values.fold(0, (a, b) => a + b);
    final rollIndex = rolloverIndex(dayData);
    final chartData = getWeeklyChartData(dailyData);
    final auditTasks =
        getCarryOverAudit([...dayData.tasks, ...dayData.backlog]);

    final focusScorePercent = focusScore(dayData);
    final dailyAvg = dailyAverage(dailyData);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your productivity intelligence breakdown.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.inkSoft),
                  ),
                ],
              ),
              const Spacer(),
              _StreakBadge(streak: streak),
            ],
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 24),

          // Metrics grid
          LayoutBuilder(
            builder: (ctx, constraints) {
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: constraints.maxWidth > 700
                        ? (constraints.maxWidth - 32) / 3
                        : double.infinity,
                    child: _CompletionCard(percent: percent, dayData: dayData),
                  ),
                  SizedBox(
                    width: constraints.maxWidth > 700
                        ? (constraints.maxWidth - 32) / 3
                        : double.infinity,
                    child: _FocusScoreCard(
                        score: focusScorePercent, dayData: dayData),
                  ),
                  SizedBox(
                    width: constraints.maxWidth > 700
                        ? (constraints.maxWidth - 32) / 3
                        : double.infinity,
                    child: _DailyAverageCard(
                        average: dailyAvg, dailyData: dailyData),
                  ),
                  SizedBox(
                    width: constraints.maxWidth > 700
                        ? (constraints.maxWidth - 16) / 2
                        : double.infinity,
                    child: _QuadrantCard(
                        qCounts: qCounts, qTotal: qTotal, dailyData: dailyData),
                  ),
                  SizedBox(
                    width: constraints.maxWidth > 700
                        ? (constraints.maxWidth - 16) / 2
                        : double.infinity,
                    child:
                        _RolloverCard(rollIndex: rollIndex, dayData: dayData),
                  ),
                ],
              );
            },
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

          const SizedBox(height: 20),

          // Bottom row
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isWide = constraints.maxWidth > 700;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 13,
                      child: _WeeklyChartCard(chartData: chartData),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 10,
                      child: _CarryOverAuditCard(tasks: auditTasks),
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _WeeklyChartCard(chartData: chartData),
                    const SizedBox(height: 16),
                    _CarryOverAuditCard(tasks: auditTasks),
                  ],
                );
              }
            },
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
        ],
      ),
    );
  }
}

// ── Streak Badge ─────────────────────────────────────────────────────────────

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13.5, vertical: 8.5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFD97706).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 5),
          Text(
            '$streak Day Streak',
            style: const TextStyle(
              color: Color(0xFFB78103),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Completion Ring Card ──────────────────────────────────────────────────────

class _CompletionCard extends StatelessWidget {
  final int percent;
  final DayData dayData;
  const _CompletionCard({required this.percent, required this.dayData});

  void _showDetails(BuildContext context, int total) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Today\'s Task Status'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Completed (${dayData.done.length}):',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (dayData.done.isEmpty)
                  const Text('No tasks completed yet.',
                      style: TextStyle(fontStyle: FontStyle.italic)),
                ...dayData.done.map((d) => ListTile(
                    title: Text(d.text),
                    subtitle: const Text('Done'),
                    dense: true)),
                const SizedBox(height: 16),
                Text(
                    'Pending (${dayData.tasks.length + dayData.backlog.length}):',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (dayData.tasks.isEmpty && dayData.backlog.isEmpty)
                  const Text('No pending tasks.',
                      style: TextStyle(fontStyle: FontStyle.italic)),
                ...dayData.tasks.map((t) => ListTile(
                    title: Text(t.text),
                    subtitle: const Text('Active'),
                    dense: true)),
                ...dayData.backlog.map((b) => ListTile(
                    title: Text(b.text),
                    subtitle: const Text('Backlog'),
                    dense: true)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('Close'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total =
        dayData.tasks.length + dayData.done.length + dayData.backlog.length;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context, total),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TASK COMPLETION',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 11,
                      letterSpacing: 0.1,
                      color: AppTheme.inkSoft,
                    ),
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: percent / 100),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOut,
                        builder: (_, value, __) => CustomPaint(
                          size: const Size(120, 120),
                          painter: _RingPainter(progress: value),
                        ),
                      ),
                      Text(
                        '$percent%',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '${dayData.done.length} of $total tasks completed today',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color baseColor;
  const _RingPainter(
      {required this.progress, this.baseColor = AppTheme.primary});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final strokeWidth = 10.0;

    final bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..shader = LinearGradient(
        colors: [baseColor, baseColor.withOpacity(0.5)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ── Quadrant Distribution Card ────────────────────────────────────────────────

class _QuadrantCard extends StatelessWidget {
  final Map<String, int> qCounts;
  final int qTotal;
  final Map<String, DayData> dailyData;
  const _QuadrantCard(
      {required this.qCounts, required this.qTotal, required this.dailyData});

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Quadrant Distribution Details'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Breakdown of tasks across all time (Backlog + Active + Done):'),
                const SizedBox(height: 16),
                ListTile(
                    title: const Text('Do First (Q1)'),
                    trailing: Text('${qCounts['q1'] ?? 0}'),
                    dense: true),
                ListTile(
                    title: const Text('Schedule (Q2)'),
                    trailing: Text('${qCounts['q2'] ?? 0}'),
                    dense: true),
                ListTile(
                    title: const Text('Delegate (Q3)'),
                    trailing: Text('${qCounts['q3'] ?? 0}'),
                    dense: true),
                ListTile(
                    title: const Text('Drop/Later (Q4)'),
                    trailing: Text('${qCounts['q4'] ?? 0}'),
                    dense: true),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('Close'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quads = [
      ('q1', 'Do First', AppTheme.doFirst),
      ('q2', 'Schedule', AppTheme.schedule),
      ('q3', 'Delegate', AppTheme.delegate),
      ('q4', 'Drop / Later', AppTheme.drop),
    ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'QUADRANT DISTRIBUTION',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 11,
                      letterSpacing: 0.1,
                      color: AppTheme.inkSoft,
                    ),
              ),
              const SizedBox(height: 20),
              ...quads.map((q) {
                final count = qCounts[q.$1] ?? 0;
                final pct = qTotal > 0 ? count / qTotal : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: q.$3,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: Text(
                          q.$2,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ),
                      Expanded(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: pct),
                          duration: const Duration(milliseconds: 600),
                          builder: (_, value, __) => ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: value,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFF1F5F9),
                              color: q.$3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 20,
                        child: Text(
                          '$count',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Rollover Index Card ────────────────────────────────────────────────────────
class _RolloverCard extends StatelessWidget {
  final int rollIndex;
  final DayData dayData;
  const _RolloverCard({required this.rollIndex, required this.dayData});

  void _showDetails(BuildContext context) {
    final active = dayData.tasks.where((t) => t.carried > 0).toList();
    final backlog = dayData.backlog.where((t) => t.carried > 0).toList();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Rollover Index Details'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tasks that have been carried over multiple days:'),
                const SizedBox(height: 16),
                ...active.map((t) => ListTile(
                    title: Text(t.text),
                    trailing: Text('${t.carried} days'),
                    subtitle: const Text('Active'),
                    dense: true)),
                ...backlog.map((t) => ListTile(
                    title: Text(t.text),
                    trailing: Text('${t.carried} days'),
                    subtitle: const Text('Backlog'),
                    dense: true)),
                if (active.isEmpty && backlog.isEmpty)
                  const Text('No carried-over tasks!'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('Close'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ROLLOVER INDEX',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 11,
                      letterSpacing: 0.1,
                      color: AppTheme.inkSoft,
                    ),
              ),
              const SizedBox(height: 40),
              Center(
                child: TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: rollIndex),
                  duration: const Duration(milliseconds: 700),
                  builder: (_, value, __) => Text(
                    '$value',
                    style: Theme.of(
                      context,
                    ).textTheme.displayLarge?.copyWith(fontSize: 52),
                  ),
                ),
              ),
              Center(
                child: Text(
                  'TOTAL CARRIES',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        letterSpacing: 0.1,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Accumulated carry-over days of all active items.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.inkSoft),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Focus Score Card ──────────────────────────────────────────────────────────
class _FocusScoreCard extends StatelessWidget {
  final int score;
  final DayData dayData;
  const _FocusScoreCard({required this.score, required this.dayData});

  void _showDetails(BuildContext context) {
    final q1q2 =
        dayData.done.where((d) => d.quad == 'q1' || d.quad == 'q2').toList();
    final others =
        dayData.done.where((d) => d.quad != 'q1' && d.quad != 'q2').toList();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Focus Score Details'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Focused (Q1 & Q2) Completed Today:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...q1q2.map((d) => ListTile(
                    title: Text(d.text),
                    subtitle: Text(d.quad == 'q1' ? 'Do First' : 'Schedule'),
                    dense: true)),
                if (q1q2.isEmpty)
                  const Text('None',
                      style: TextStyle(fontStyle: FontStyle.italic)),
                const SizedBox(height: 16),
                const Text('Other Tasks Completed Today:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...others.map((d) => ListTile(
                    title: Text(d.text),
                    subtitle: Text(d.quad == 'q3'
                        ? 'Delegate'
                        : (d.quad == 'q4' ? 'Drop' : 'Uncategorized')),
                    dense: true)),
                if (others.isEmpty)
                  const Text('None',
                      style: TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('Close'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FOCUS SCORE',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 11,
                      letterSpacing: 0.1,
                      color: AppTheme.inkSoft,
                    ),
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: score / 100),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOut,
                        builder: (_, value, __) => CustomPaint(
                          size: const Size(120, 120),
                          painter: _RingPainter(
                              progress: value, baseColor: AppTheme.doFirst),
                        ),
                      ),
                      Text(
                        '$score%',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'High priority output today',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Daily Average Card ────────────────────────────────────────────────────────
class _DailyAverageCard extends StatelessWidget {
  final double average;
  final Map<String, DayData> dailyData;
  const _DailyAverageCard({required this.average, required this.dailyData});

  void _showDetails(BuildContext context) {
    final recentDays = getWeeklyChartData(dailyData);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('7-Day Average Details'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Completed tasks over the past 7 days:'),
                const SizedBox(height: 16),
                ...recentDays.reversed.map((d) => ListTile(
                      title:
                          Text(d.dateStr == todayStr() ? 'Today' : d.dateStr),
                      trailing: Text('${d.completedCount}'),
                      dense: true,
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('Close'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '7-DAY AVERAGE',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 11,
                      letterSpacing: 0.1,
                      color: AppTheme.inkSoft,
                    ),
              ),
              const SizedBox(height: 40),
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: average),
                  duration: const Duration(milliseconds: 700),
                  builder: (_, value, __) => Text(
                    value.toStringAsFixed(1),
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge
                        ?.copyWith(fontSize: 52),
                  ),
                ),
              ),
              Center(
                child: Text(
                  'COMPLETIONS / DAY',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 0.1, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Average tasks completed daily.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.inkSoft),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Weekly Chart Card ─────────────────────────────────────────────────────────

class _WeeklyChartCard extends StatelessWidget {
  final List<WeeklyChartEntry> chartData;
  const _WeeklyChartCard({required this.chartData});

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Weekly Productivity Details'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily stats for the past 7 days:'),
                const SizedBox(height: 16),
                ...chartData.map((d) => ListTile(
                      title: Text(d.dateStr),
                      subtitle: Text(
                          '${d.completedCount} completed, ${d.activeCount} remaining'),
                      dense: true,
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('Close'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = chartData.map((e) => e.completedCount).fold(2, math.max);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WEEKLY PRODUCTIVITY',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 11,
                      letterSpacing: 0.1,
                      color: AppTheme.inkSoft,
                    ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: chartData.map((e) {
                    final fraction = maxVal > 0
                        ? (e.completedCount / maxVal).clamp(0.02, 1.0)
                        : 0.02;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${e.completedCount}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: fraction.toDouble()),
                              duration: const Duration(milliseconds: 700),
                              builder: (_, v, __) => Container(
                                height: 120 * v,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppTheme.primaryLight,
                                      AppTheme.primary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              e.dayLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.inkSoft,
                                    fontSize: 11,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('Completed',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Carry-Over Audit Card ─────────────────────────────────────────────────────

class _Animated3DGem extends StatelessWidget {
  const _Animated3DGem();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 5,
                )
              ],
            ),
          ),
          // 3D Isometric Diamond
          Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002) // Perspective
              ..rotateX(1.0)
              ..rotateZ(math.pi / 4),
            alignment: Alignment.center,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    AppTheme.primary,
                    Color(0xFF1E3A8A),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0xFF1E3A8A),
                      offset: Offset(2, 5),
                      blurRadius: 0),
                  BoxShadow(
                      color: Colors.black26,
                      offset: Offset(4, 10),
                      blurRadius: 10),
                ],
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 6.seconds, begin: 0, end: 1)
              .shimmer(duration: 2.seconds, angle: math.pi / 2, size: 2),
        ],
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).moveY(
        begin: -5, end: 5, duration: 1.5.seconds, curve: Curves.easeInOut);
  }
}

class _CarryOverAuditCard extends StatelessWidget {
  final List<TaskModel> tasks;
  const _CarryOverAuditCard({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CARRY-OVER AUDIT',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 11,
                    letterSpacing: 0.1,
                    color: AppTheme.inkSoft,
                  ),
            ),
            const SizedBox(height: 16),
            if (tasks.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const _Animated3DGem(),
                      const SizedBox(height: 8),
                      Text(
                        'No stuck tasks! Great work.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...tasks.map((t) {
                String tip = 'Try breaking this down into smaller steps.';
                if (t.quad == 'q1')
                  tip = 'High urgency — tackle this now!';
                else if (t.quad == 'q2')
                  tip = 'Schedule a deep-work block for this.';
                else if (t.quad == 'q3')
                  tip = 'Can someone else handle this?';
                else if (t.quad == 'q4') tip = 'Consider dropping this task.';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border(
                      left: BorderSide(color: AppTheme.delegate, width: 3),
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.text,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.ink,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tip,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.delegateBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '↻ ${t.carried}d',
                          style: const TextStyle(
                            color: AppTheme.delegate,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
