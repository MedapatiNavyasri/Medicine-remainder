import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medicine_reminder/main.dart';
import 'package:medicine_reminder/models/medicine.dart';
import 'package:medicine_reminder/models/dose_history.dart';
import 'package:medicine_reminder/services/reminder_service.dart';
import 'package:medicine_reminder/services/storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('MediReminder smoke test loads app bar and navigation',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MediReminderApp());
    await tester.pumpAndSettle();

    // Verify MediReminder title appears in AppBar
    expect(find.text('MediReminder'), findsWidgets);

    // Verify Dashboard navigation items appear
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Medicines'), findsWidgets);
    expect(find.text('History'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });

  test('ReminderService calculates scheduled doses and metrics correctly', () {
    final reminderService = ReminderService();
    final now = DateTime(2026, 10, 22, 9, 30); // 9:30 AM

    final med1 = Medicine(
      id: 'test_1',
      name: 'Amoxicillin',
      dosage: '500 mg',
      type: MedicineType.capsule,
      instructions: MedicineInstruction.afterFood,
      schedule: MedicineSchedule(
        frequency: MedicineFrequency.twiceDaily,
        reminderTimes: const ['08:00', '20:00'],
        startDate: DateTime(2026, 10, 20),
        endDate: DateTime(2026, 10, 25),
      ),
      createdAt: DateTime(2026, 10, 20),
    );

    // Scheduled at 08:00 AM (90 mins ago, no history yet) -> missed
    // Scheduled at 20:00 PM (future) -> upcoming
    final doses = reminderService.getScheduledDosesForDate(
      targetDate: now,
      medicines: [med1],
      history: [],
      referenceTime: now,
    );

    expect(doses.length, 2);
    expect(doses[0].status, DoseOccurrenceStatus.missed);
    expect(doses[1].status, DoseOccurrenceStatus.upcoming);

    // Now record history for the 08:00 dose as taken
    final historyItem = DoseHistory(
      id: 'hist_1',
      medicineId: 'test_1',
      medicineName: 'Amoxicillin',
      dosage: '500 mg',
      scheduledDateTime: DateTime(2026, 10, 22, 8, 0),
      actionDateTime: DateTime(2026, 10, 22, 8, 15),
      status: DoseStatus.taken,
    );

    final updatedDoses = reminderService.getScheduledDosesForDate(
      targetDate: now,
      medicines: [med1],
      history: [historyItem],
      referenceTime: now,
    );

    expect(updatedDoses[0].status, DoseOccurrenceStatus.taken);
    expect(updatedDoses[1].status, DoseOccurrenceStatus.upcoming);

    // Dashboard metrics
    final metrics = reminderService.calculateDashboardMetrics(
      medicines: [med1],
      history: [historyItem],
      referenceTime: now,
    );

    expect(metrics.totalMedicines, 1);
    expect(metrics.scheduledTodayCount, 2);
    expect(metrics.takenTodayCount, 1);
    expect(metrics.upcomingCount, 1);
    expect(metrics.missedOrPendingCount, 0);
    expect(metrics.nextDose?.timeString, '20:00');
  });

  test('StorageService persists and updates medicines correctly', () async {
    final storage = StorageService();
    final med = Medicine(
      id: 'test_med_storage',
      name: 'Ibuprofen',
      dosage: '400 mg',
      type: MedicineType.tablet,
      instructions: MedicineInstruction.withFood,
      schedule: MedicineSchedule(
        frequency: MedicineFrequency.onceDaily,
        reminderTimes: const ['12:00'],
        startDate: DateTime(2026, 10, 22),
        endDate: DateTime(2026, 10, 28),
      ),
      createdAt: DateTime(2026, 10, 22),
    );

    await storage.saveMedicine(med);
    var meds = await storage.getMedicines();
    expect(meds.length, 1);
    expect(meds.first.name, 'Ibuprofen');

    // Update medicine
    final updated = med.copyWith(dosage: '200 mg');
    await storage.saveMedicine(updated);
    meds = await storage.getMedicines();
    expect(meds.length, 1);
    expect(meds.first.dosage, '200 mg');

    // Delete medicine
    await storage.deleteMedicine(med.id);
    meds = await storage.getMedicines();
    expect(meds.isEmpty, true);
  });
}
