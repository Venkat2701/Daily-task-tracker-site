import 'package:flutter_test/flutter_test.dart';
import 'package:daily_task_tracker/shared/utils/date_utils.dart';

void main() {
  group('Date Utils Tests', () {
    test('todayStr returns correct format', () {
      final str = todayStr();
      expect(str, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });

    test('formatDateLabel formats nicely', () {
      final formatted = formatDateLabel('2026-07-09');
      expect(formatted, contains('Thursday'));
      expect(formatted, contains('July'));
      expect(formatted, contains('9'));
    });

    test('parseLocalDate parses exact parts', () {
      final date = parseLocalDate('2026-07-09');
      expect(date.year, 2026);
      expect(date.month, 7);
      expect(date.day, 9);
    });

    test('shortDayLabel returns EEE', () {
      final label = shortDayLabel('2026-07-09');
      expect(label, 'Thu');
    });

    test('daysBetween calculatues difference', () {
      final diff = daysBetween('2026-07-01', '2026-07-09');
      expect(diff, 8);
    });

    test('adjustDateStr offsets accurately', () {
      final shifted = adjustDateStr('2026-07-09', -1);
      expect(shifted, '2026-07-08');

      final shiftedForward = adjustDateStr('2026-07-09', 2);
      expect(shiftedForward, '2026-07-11');
    });
  });
}
