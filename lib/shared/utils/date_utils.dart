import 'package:intl/intl.dart';

/// Returns today as YYYY-MM-DD string.
String todayStr() {
  final now = DateTime.now();
  return _formatDate(now);
}

/// Returns YYYY-MM-DD string offset by [days] from today.
String getOffsetDateStr(int days) {
  final d = DateTime.now().add(Duration(days: days));
  return _formatDate(d);
}

/// Formats any DateTime to YYYY-MM-DD.
String _formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Parses YYYY-MM-DD safely in local timezone.
DateTime parseLocalDate(String dateStr) {
  final parts = dateStr.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

/// Human-readable label: "Monday, July 9, 2026"
String formatDateLabel(String dateStr) {
  final d = parseLocalDate(dateStr);
  return DateFormat('EEEE, MMMM d, yyyy').format(d);
}

/// Short day label: "Mon"
String shortDayLabel(String dateStr) {
  final d = parseLocalDate(dateStr);
  return DateFormat('EEE').format(d);
}

/// Number of calendar days between two YYYY-MM-DD strings (min 1).
int daysBetween(String a, String b) {
  final dA = parseLocalDate(a);
  final dB = parseLocalDate(b);
  return dB.difference(dA).inDays.clamp(1, 9999);
}

/// Adjust a YYYY-MM-DD string by [days] offset.
String adjustDateStr(String dateStr, int days) {
  final d = parseLocalDate(dateStr).add(Duration(days: days));
  return _formatDate(d);
}
