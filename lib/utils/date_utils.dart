import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _dateFormat = DateFormat('MMM d, y');
  static final DateFormat _dateTimeFormat = DateFormat('MMM d, y • h:mm a');
  static final DateFormat _timeFormat = DateFormat('h:mm a');

  /// Formats a DateTime as "Oct 22, 2026".
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return _dateFormat.format(date);
  }

  /// Formats a DateTime as "Oct 22, 2026 • 8:30 AM".
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return _dateTimeFormat.format(dateTime);
  }

  /// Formats a 24-hour "HH:mm" string as 12-hour "8:00 AM".
  static String formatTimeString(String timeString) {
    final parts = timeString.split(':');
    if (parts.length != 2) return timeString;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, hour, minute);
    return _timeFormat.format(dt);
  }

  /// Formats a TimeOfDay as "8:00 AM".
  static String formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return _timeFormat.format(dt);
  }

  /// Converts TimeOfDay to a 24-hour string: "08:00".
  static String timeOfDayToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Parses a 24-hour "HH:mm" string into a TimeOfDay.
  static TimeOfDay stringToTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    if (parts.length != 2) return const TimeOfDay(hour: 8, minute: 0);
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Strips the time component from a DateTime, preserving only the calendar date.
  static DateTime dateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// Checks if two dates fall on the exact same calendar day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Checks if [target] falls between [start] and [end], inclusive of calendar dates.
  static bool isDateWithinRange(DateTime target, DateTime start, DateTime end) {
    final targetDay = dateOnly(target);
    final startDay = dateOnly(start);
    final endDay = dateOnly(end);

    return (targetDay.isAtSameMomentAs(startDay) || targetDay.isAfter(startDay)) &&
        (targetDay.isAtSameMomentAs(endDay) || targetDay.isBefore(endDay));
  }

  /// Combines a calendar date with a 24-hour "HH:mm" time string.
  static DateTime combineDateAndTime(DateTime date, String timeString) {
    final parts = timeString.split(':');
    final hour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 0) : 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}
