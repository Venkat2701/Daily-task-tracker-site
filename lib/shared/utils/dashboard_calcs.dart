import '../models/models.dart';
import 'date_utils.dart';

/// All dashboard calculations are pure functions — no Flutter, no Firebase.
/// Easily unit-testable.

/// Returns the completion ring percentage for a given day's data (0–100).
int completionPercent(DayData? dayData) {
  if (dayData == null) return 0;
  final total =
      dayData.tasks.length + dayData.done.length + dayData.backlog.length;
  if (total == 0) return 0;
  return ((dayData.done.length / total) * 100).round();
}

/// Returns the percentage of completed tasks that were Important (Q1/Q2) for a given day.
int focusScore(DayData? dayData) {
  if (dayData == null) return 0;
  final totalDone = dayData.done.length;
  if (totalDone == 0) return 0;
  final focusedDone =
      dayData.done.where((d) => d.quad == 'q1' || d.quad == 'q2').length;
  return ((focusedDone / totalDone) * 100).round();
}

/// Returns the average number of completed tasks per day over the last 7 days.
double dailyAverage(Map<String, DayData> dailyData) {
  int totalDone = 0;
  for (int i = -6; i <= 0; i++) {
    final dStr = getOffsetDateStr(i);
    totalDone += dailyData[dStr]?.done.length ?? 0;
  }
  return totalDone / 7.0;
}

/// Counts tasks per quadrant across ALL days.
Map<String, int> getQuadrantCounts(Map<String, DayData> dailyData) {
  final counts = {'q1': 0, 'q2': 0, 'q3': 0, 'q4': 0};
  for (final day in dailyData.values) {
    for (final t in day.tasks) {
      if (t.quad != null && counts.containsKey(t.quad)) {
        counts[t.quad!] = (counts[t.quad!] ?? 0) + 1;
      }
    }
    for (final d in day.done) {
      if (d.quad != null && counts.containsKey(d.quad)) {
        counts[d.quad!] = (counts[d.quad!] ?? 0) + 1;
      }
    }
    for (final b in day.backlog) {
      if (b.quad != null && counts.containsKey(b.quad)) {
        counts[b.quad!] = (counts[b.quad!] ?? 0) + 1;
      }
    }
  }
  return counts;
}

/// Returns total carry-over index (sum of all carried values for today's tasks).
int rolloverIndex(DayData? dayData) {
  if (dayData == null) return 0;
  final activeCarry = dayData.tasks.fold(0, (sum, t) => sum + t.carried);
  final backlogCarry = dayData.backlog.fold(0, (sum, t) => sum + t.carried);
  return activeCarry + backlogCarry;
}

/// Calculates productivity streak (consecutive days with at least 1 done task).
int calculateStreak(Map<String, DayData> dailyData) {
  final today = todayStr();
  final yesterday = getOffsetDateStr(-1);

  final hasDoneToday = (dailyData[today]?.done.isNotEmpty) ?? false;
  final hasDoneYesterday = (dailyData[yesterday]?.done.isNotEmpty) ?? false;

  if (!hasDoneToday && !hasDoneYesterday) return 0;

  int offset = hasDoneToday ? 0 : -1;
  int streak = 0;

  while (true) {
    final dStr = getOffsetDateStr(offset);
    final dayDone = dailyData[dStr]?.done ?? [];
    if (dayDone.isNotEmpty) {
      streak++;
      offset--;
    } else {
      break;
    }
  }
  return streak;
}

class WeeklyChartEntry {
  final String dayLabel;
  final int completedCount;
  final int activeCount;
  final String dateStr;

  const WeeklyChartEntry({
    required this.dayLabel,
    required this.completedCount,
    required this.activeCount,
    required this.dateStr,
  });
}

/// Returns 7-day productivity data (last 6 days + today).
List<WeeklyChartEntry> getWeeklyChartData(Map<String, DayData> dailyData) {
  final result = <WeeklyChartEntry>[];
  for (int i = -6; i <= 0; i++) {
    final dStr = getOffsetDateStr(i);
    final dayData = dailyData[dStr];
    result.add(
      WeeklyChartEntry(
        dayLabel: shortDayLabel(dStr),
        completedCount: dayData?.done.length ?? 0,
        activeCount:
            (dayData?.tasks.length ?? 0) + (dayData?.backlog.length ?? 0),
        dateStr: dStr,
      ),
    );
  }
  return result;
}

/// Returns tasks with the highest carry count (for the audit panel).
List<TaskModel> getCarryOverAudit(List<TaskModel> tasks, {int max = 4}) {
  return tasks.where((t) => t.carried >= 1).toList()
    ..sort((a, b) => b.carried.compareTo(a.carried))
    ..take(max);
}

extension TakeExt<T> on List<T> {
  List<T> take(int n) => length <= n ? this : sublist(0, n);
}
