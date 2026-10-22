import '../models/medicine.dart';
import '../models/dose_history.dart';
import '../utils/date_utils.dart';

/// The calculated status of an individual scheduled dose occurrence.
enum DoseOccurrenceStatus {
  taken,
  skipped,
  due,
  missed,
  upcoming,
}

/// Represents a single dose occurrence for a medicine on a specific date and time.
class ScheduledDose {
  final Medicine medicine;
  final DateTime scheduledDateTime;
  final String timeString; // "08:00"
  final DoseOccurrenceStatus status;
  final DoseHistory? historyRecord;

  const ScheduledDose({
    required this.medicine,
    required this.scheduledDateTime,
    required this.timeString,
    required this.status,
    this.historyRecord,
  });

  String get occurrenceKey =>
      DoseHistory.generateOccurrenceKey(medicine.id, scheduledDateTime);

  bool get isActionable =>
      status == DoseOccurrenceStatus.due ||
      status == DoseOccurrenceStatus.missed ||
      status == DoseOccurrenceStatus.upcoming;
}

/// Dashboard summary counters for today.
class DashboardMetrics {
  final int totalMedicines;
  final int scheduledTodayCount;
  final int takenTodayCount;
  final int upcomingCount;
  final int missedOrPendingCount;
  final ScheduledDose? nextDose;

  const DashboardMetrics({
    required this.totalMedicines,
    required this.scheduledTodayCount,
    required this.takenTodayCount,
    required this.upcomingCount,
    required this.missedOrPendingCount,
    this.nextDose,
  });
}

/// Business logic service for calculating medicine schedules, due doses,
/// missed doses, and dashboard metrics.
class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  /// Calculates all scheduled dose occurrences for [targetDate].
  List<ScheduledDose> getScheduledDosesForDate({
    required DateTime targetDate,
    required List<Medicine> medicines,
    required List<DoseHistory> history,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final today = AppDateUtils.dateOnly(now);
    final targetDay = AppDateUtils.dateOnly(targetDate);

    // Map existing history records by occurrence key for fast lookup
    final historyMap = <String, DoseHistory>{};
    for (final record in history) {
      historyMap[record.occurrenceKey] = record;
    }

    final List<ScheduledDose> result = [];

    // Filter active medicines whose date ranges cover targetDate
    final applicableMedicines = medicines.where((med) {
      if (!med.isActive) return false;
      return AppDateUtils.isDateWithinRange(
        targetDay,
        med.schedule.startDate,
        med.schedule.endDate,
      );
    });

    for (final medicine in applicableMedicines) {
      for (final timeStr in medicine.schedule.reminderTimes) {
        final scheduledDateTime =
            AppDateUtils.combineDateAndTime(targetDay, timeStr);
        final key = DoseHistory.generateOccurrenceKey(
          medicine.id,
          scheduledDateTime,
        );

        final historyRecord = historyMap[key];
        DoseOccurrenceStatus status;

        if (historyRecord != null) {
          if (historyRecord.status == DoseStatus.taken) {
            status = DoseOccurrenceStatus.taken;
          } else {
            status = DoseOccurrenceStatus.skipped;
          }
        } else {
          // No history action taken yet
          if (targetDay.isBefore(today)) {
            // Past day dose that was never marked
            status = DoseOccurrenceStatus.missed;
          } else if (targetDay.isAfter(today)) {
            // Future day
            status = DoseOccurrenceStatus.upcoming;
          } else {
            // Today
            if (scheduledDateTime.isAfter(now)) {
              status = DoseOccurrenceStatus.upcoming;
            } else {
              final minutesPassed =
                  now.difference(scheduledDateTime).inMinutes;
              // Due window: within 60 minutes after scheduled time
              if (minutesPassed <= 60) {
                status = DoseOccurrenceStatus.due;
              } else {
                // Scheduled time was over 60 minutes ago without action
                status = DoseOccurrenceStatus.missed;
              }
            }
          }
        }

        result.add(
          ScheduledDose(
            medicine: medicine,
            scheduledDateTime: scheduledDateTime,
            timeString: timeStr,
            status: status,
            historyRecord: historyRecord,
          ),
        );
      }
    }

    // Sort chronologically by scheduled time, then medicine name
    result.sort((a, b) {
      final cmp = a.scheduledDateTime.compareTo(b.scheduledDateTime);
      if (cmp != 0) return cmp;
      return a.medicine.name.compareTo(b.medicine.name);
    });

    return result;
  }

  /// Calculates aggregated metrics for the dashboard.
  DashboardMetrics calculateDashboardMetrics({
    required List<Medicine> medicines,
    required List<DoseHistory> history,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final todayDoses = getScheduledDosesForDate(
      targetDate: now,
      medicines: medicines,
      history: history,
      referenceTime: now,
    );

    int takenCount = 0;
    int upcomingCount = 0;
    int missedOrPendingCount = 0;
    ScheduledDose? nextDose;

    for (final dose in todayDoses) {
      if (dose.status == DoseOccurrenceStatus.taken) {
        takenCount++;
      } else if (dose.status == DoseOccurrenceStatus.upcoming) {
        upcomingCount++;
        nextDose ??= dose;
      } else if (dose.status == DoseOccurrenceStatus.due) {
        missedOrPendingCount++;
        // If due, it's also the immediate next dose to take
        nextDose ??= dose;
      } else if (dose.status == DoseOccurrenceStatus.missed) {
        missedOrPendingCount++;
      }
    }

    return DashboardMetrics(
      totalMedicines: medicines.length,
      scheduledTodayCount: todayDoses.length,
      takenTodayCount: takenCount,
      upcomingCount: upcomingCount,
      missedOrPendingCount: missedOrPendingCount,
      nextDose: nextDose,
    );
  }
}
