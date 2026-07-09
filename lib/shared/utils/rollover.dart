import '../models/models.dart';

/// Pure rollover logic — no side effects, fully unit testable.
Map<String, DayData> rolloverTasks(
  Map<String, DayData> dailyData,
  String today,
) {
  // Skip if today already rolled over
  final todayData = dailyData[today];
  if (todayData != null && todayData.lastRolloverDate == today) {
    return dailyData;
  }

  // Find the most recent day before today that has tasks
  final pastDates = dailyData.keys.where((d) => d.compareTo(today) < 0).toList()
    ..sort((a, b) => b.compareTo(a));

  if (pastDates.isEmpty) {
    return {
      ...dailyData,
      today: (dailyData[today] ?? DayData.empty()).copyWith(
        lastRolloverDate: today,
      ),
    };
  }

  final lastActiveDay = pastDates.first;
  final previousTasks = dailyData[lastActiveDay]?.tasks ?? [];

  if (previousTasks.isEmpty) {
    return {
      ...dailyData,
      today: (dailyData[today] ?? DayData.empty()).copyWith(
        lastRolloverDate: today,
      ),
    };
  }

  final currentTodayData = dailyData[today] ?? DayData.empty();
  final existingIds = currentTodayData.tasks.map((t) => t.id).toSet();

  final carryInc = daysBetween(lastActiveDay, today);

  final newTasks = [
    ...currentTodayData.tasks,
    for (final task in previousTasks)
      if (!existingIds.contains(task.id))
        task.copyWith(day: today, carried: (task.carried) + carryInc),
  ];

  return {
    ...dailyData,
    today: currentTodayData.copyWith(tasks: newTasks, lastRolloverDate: today),
  };
}

int daysBetween(String a, String b) {
  final dateA = DateTime.parse(a);
  final dateB = DateTime.parse(b);
  return dateB.difference(dateA).inDays.clamp(1, 9999);
}
