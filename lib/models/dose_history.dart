/// Status options for a scheduled dose.
class DoseStatus {
  static const String taken = 'Taken';
  static const String skipped = 'Skipped';

  static const List<String> all = [taken, skipped];
}

/// Represents an individual dose action recorded by the user.
/// Stored separately from Medicine records to preserve history integrity.
class DoseHistory {
  final String id;
  final String medicineId;
  final String medicineName;
  final String dosage;
  final DateTime scheduledDateTime;
  final DateTime actionDateTime;
  final String status; // 'Taken' or 'Skipped'
  final String notes;

  const DoseHistory({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.dosage,
    required this.scheduledDateTime,
    required this.actionDateTime,
    required this.status,
    this.notes = '',
  });

  /// Computes a unique key for a medicine dose occurrence on a specific date and time.
  /// Format: `<medicineId>_<YYYY-MM-DD>_<HH:mm>`
  static String generateOccurrenceKey(String medicineId, DateTime scheduledDateTime) {
    final year = scheduledDateTime.year.toString().padLeft(4, '0');
    final month = scheduledDateTime.month.toString().padLeft(2, '0');
    final day = scheduledDateTime.day.toString().padLeft(2, '0');
    final hour = scheduledDateTime.hour.toString().padLeft(2, '0');
    final minute = scheduledDateTime.minute.toString().padLeft(2, '0');
    return '${medicineId}_$year-$month-${day}_$hour:$minute';
  }

  /// Returns the occurrence key of this history record.
  String get occurrenceKey => generateOccurrenceKey(medicineId, scheduledDateTime);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'dosage': dosage,
      'scheduledDateTime': scheduledDateTime.toIso8601String(),
      'actionDateTime': actionDateTime.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  factory DoseHistory.fromJson(Map<String, dynamic> json) {
    return DoseHistory(
      id: json['id']?.toString() ?? '',
      medicineId: json['medicineId']?.toString() ?? '',
      medicineName: json['medicineName']?.toString() ?? 'Medicine',
      dosage: json['dosage']?.toString() ?? '',
      scheduledDateTime: json['scheduledDateTime'] != null
          ? DateTime.tryParse(json['scheduledDateTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      actionDateTime: json['actionDateTime'] != null
          ? DateTime.tryParse(json['actionDateTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: json['status']?.toString() ?? DoseStatus.taken,
      notes: json['notes']?.toString() ?? '',
    );
  }
}
