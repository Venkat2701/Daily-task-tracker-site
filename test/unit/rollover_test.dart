import 'package:flutter_test/flutter_test.dart';
import 'package:daily_task_tracker/shared/models/models.dart';
import 'package:daily_task_tracker/shared/utils/rollover.dart';

void main() {
  group('Rollover Logic Tests', () {
    test('skips if already rolled over today', () {
      final initial = {
        '2026-07-09': DayData(lastRolloverDate: '2026-07-09', tasks: [])
      };

      final result = rolloverTasks(initial, '2026-07-09');
      // Returns exact same instance or equivalent
      expect(result['2026-07-09']?.lastRolloverDate, '2026-07-09');
    });

    test('marks today as rolled over if no past tasks exist', () {
      final initial = <String, DayData>{
        '2026-07-08': DayData.empty(), // Empty previous day
      };

      final result = rolloverTasks(initial, '2026-07-09');
      expect(result['2026-07-09']?.lastRolloverDate, '2026-07-09');
      expect(result['2026-07-09']?.tasks.isEmpty, true);
    });

    test('carries over tasks from the most recent active past date', () {
      final t1 = TaskModel(id: 't1', text: 'T1', day: '2026-07-07');
      final t2 = TaskModel(id: 't2', text: 'T2', day: '2026-07-07');

      final initial = <String, DayData>{
        '2026-07-07': DayData(tasks: [t1, t2]),
        // Skip 2026-07-08
      };

      final result = rolloverTasks(initial, '2026-07-09');

      final todayData = result['2026-07-09']!;
      expect(todayData.lastRolloverDate, '2026-07-09');
      expect(todayData.tasks.length, 2);

      // Carried increment should be 2 days (09 - 07 = 2)
      expect(todayData.tasks[0].id, 't1');
      expect(todayData.tasks[0].carried, 2);
      expect(todayData.tasks[0].day, '2026-07-09');
    });

    test('avoids duplicating tasks if they already exist in today', () {
      final t1 = TaskModel(id: 't1', text: 'T1', day: '2026-07-08');

      final initialTodayTask =
          TaskModel(id: 't1', text: 'T1 modified', day: '2026-07-09');

      final initial = <String, DayData>{
        '2026-07-08': DayData(tasks: [t1]),
        '2026-07-09': DayData(tasks: [initialTodayTask]),
      };

      final result = rolloverTasks(initial, '2026-07-09');
      final todayData = result['2026-07-09']!;

      expect(todayData.tasks.length, 1);
      // Keeps the existing task version
      expect(todayData.tasks[0].text, 'T1 modified');
    });
  });
}
