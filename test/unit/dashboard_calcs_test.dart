import 'package:flutter_test/flutter_test.dart';
import 'package:daily_task_tracker/shared/models/models.dart';
import 'package:daily_task_tracker/shared/utils/dashboard_calcs.dart';

void main() {
  group('Dashboard Calcs Tests', () {
    test('completionPercent calculates correctly', () {
      final task1 = TaskModel(id: 't1', text: 'Task 1', day: '2026-07-09');
      final done1 = DoneItem(
          id: 'd1', text: 'Done 1', date: '2026-07-09', completedAt: '');

      final dayData = DayData(tasks: [task1], done: [done1]);

      expect(completionPercent(dayData), 50);
      expect(completionPercent(null), 0);
      expect(completionPercent(DayData.empty()), 0);
    });

    test('getQuadrantCounts sums tasks and done items', () {
      final t1 = TaskModel(id: 't1', text: 'T1', quad: 'q1', day: '...');
      final t2 = TaskModel(id: 't2', text: 'T2', quad: 'q1', day: '...');
      final d1 = DoneItem(
          id: 'd1', text: 'D1', quad: 'q2', date: '...', completedAt: '');
      final dayData = DayData(tasks: [t1, t2], done: [d1]);

      final counts = getQuadrantCounts({'day1': dayData});

      expect(counts['q1'], 2);
      expect(counts['q2'], 1);
      expect(counts['q3'], 0);
      expect(counts['q4'], 0);
    });

    test('rolloverIndex sums carry counts', () {
      final t1 = TaskModel(id: '1', text: 'A', day: 'd', carried: 3);
      final t2 = TaskModel(id: '2', text: 'B', day: 'd', carried: 2);

      final dayData = DayData(tasks: [t1, t2]);
      expect(rolloverIndex(dayData), 5);
      expect(rolloverIndex(null), 0);
    });

    test('getCarryOverAudit returns sorted top carried tasks', () {
      final t1 = TaskModel(id: '1', text: 'A', day: 'd', carried: 1);
      final t2 = TaskModel(id: '2', text: 'B', day: 'd', carried: 5);
      final t3 = TaskModel(id: '3', text: 'C', day: 'd', carried: 3);
      final t4 = TaskModel(id: '4', text: 'D', day: 'd', carried: 0);

      final audit = getCarryOverAudit([t1, t2, t3, t4]);

      expect(audit.length, 3); // excludes carried: 0
      expect(audit[0].id, '2'); // highest first
      expect(audit[1].id, '3');
      expect(audit[2].id, '1');
    });
  });
}
