import 'date_utils.dart';

class Validators {
  /// Validates that a string field is not empty.
  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates medicine name.
  static String? medicineName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the medicine name';
    }
    if (value.trim().length < 2) {
      return 'Medicine name must be at least 2 characters';
    }
    return null;
  }

  /// Validates dosage.
  static String? dosage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the dosage (e.g. 1 tablet, 5 ml)';
    }
    return null;
  }

  /// Validates that end date is on or after start date.
  static String? dateRange(DateTime? start, DateTime? end) {
    if (start == null) {
      return 'Start date is required';
    }
    if (end == null) {
      return 'End date is required';
    }
    final startDay = AppDateUtils.dateOnly(start);
    final endDay = AppDateUtils.dateOnly(end);
    if (endDay.isBefore(startDay)) {
      return 'End date cannot be earlier than start date';
    }
    return null;
  }

  /// Validates reminder times list.
  static String? reminderTimes(List<String> times) {
    if (times.isEmpty) {
      return 'Please set at least one reminder time';
    }
    final uniqueTimes = times.toSet();
    if (uniqueTimes.length != times.length) {
      return 'Reminder times cannot contain duplicates';
    }
    return null;
  }
}
