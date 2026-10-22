import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine.dart';
import '../models/dose_history.dart';

/// Service responsible for managing local persistence of medications
/// and dose history records using SharedPreferences.
class StorageService {
  static const String _medicinesKey = 'mediremind_medicines_v1';
  static const String _historyKey = 'mediremind_dose_history_v1';

  // Singleton pattern for convenient app-wide access
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// Retrieves all saved medicines. Returns an empty list if no data exists
  /// or if parsing fails.
  Future<List<Medicine>> getMedicines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_medicinesKey);
      if (jsonString == null || jsonString.trim().isEmpty) {
        return [];
      }

      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded
            .map((item) {
              try {
                if (item is Map<String, dynamic>) {
                  return Medicine.fromJson(item);
                } else if (item is Map) {
                  return Medicine.fromJson(Map<String, dynamic>.from(item));
                }
              } catch (e) {
                debugPrint('Error parsing single medicine: $e');
              }
              return null;
            })
            .whereType<Medicine>()
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Failed to load medicines from local storage: $e');
      return [];
    }
  }

  /// Saves a medicine (either inserting a new one or updating an existing one).
  Future<bool> saveMedicine(Medicine medicine) async {
    try {
      final medicines = await getMedicines();
      final index = medicines.indexWhere((m) => m.id == medicine.id);

      if (index >= 0) {
        medicines[index] = medicine;
      } else {
        medicines.add(medicine);
      }

      return await _saveMedicinesList(medicines);
    } catch (e) {
      debugPrint('Error saving medicine: $e');
      return false;
    }
  }

  /// Deletes a medicine by ID. Note that dose history is intentionally preserved.
  Future<bool> deleteMedicine(String id) async {
    try {
      final medicines = await getMedicines();
      medicines.removeWhere((m) => m.id == id);
      return await _saveMedicinesList(medicines);
    } catch (e) {
      debugPrint('Error deleting medicine: $e');
      return false;
    }
  }

  /// Toggles active/inactive status for a medicine.
  Future<bool> toggleMedicineStatus(String id, bool isActive) async {
    try {
      final medicines = await getMedicines();
      final index = medicines.indexWhere((m) => m.id == id);
      if (index >= 0) {
        medicines[index] = medicines[index].copyWith(isActive: isActive);
        return await _saveMedicinesList(medicines);
      }
      return false;
    } catch (e) {
      debugPrint('Error toggling medicine status: $e');
      return false;
    }
  }

  /// Internal helper to persist the full medicine list as JSON.
  Future<bool> _saveMedicinesList(List<Medicine> medicines) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(medicines.map((m) => m.toJson()).toList());
    return await prefs.setString(_medicinesKey, jsonString);
  }

  // -------------------------------------------------------------
  // Dose History Methods
  // -------------------------------------------------------------

  /// Retrieves all recorded dose history items.
  Future<List<DoseHistory>> getDoseHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_historyKey);
      if (jsonString == null || jsonString.trim().isEmpty) {
        return [];
      }

      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is List) {
        final list = decoded
            .map((item) {
              try {
                if (item is Map<String, dynamic>) {
                  return DoseHistory.fromJson(item);
                } else if (item is Map) {
                  return DoseHistory.fromJson(Map<String, dynamic>.from(item));
                }
              } catch (e) {
                debugPrint('Error parsing dose record: $e');
              }
              return null;
            })
            .whereType<DoseHistory>()
            .toList();

        // Sort descending by action or scheduled time
        list.sort((a, b) => b.scheduledDateTime.compareTo(a.scheduledDateTime));
        return list;
      }
      return [];
    } catch (e) {
      debugPrint('Failed to load dose history from local storage: $e');
      return [];
    }
  }

  /// Records a dose (Taken or Skipped).
  /// If a record for this exact scheduled occurrence already exists, it updates it,
  /// preventing duplicate history records for the same dose.
  Future<bool> recordDose(DoseHistory dose) async {
    try {
      final history = await getDoseHistory();
      final existingIndex = history.indexWhere((item) =>
          item.occurrenceKey == dose.occurrenceKey);

      if (existingIndex >= 0) {
        history[existingIndex] = dose;
      } else {
        history.insert(0, dose);
      }

      return await _saveHistoryList(history);
    } catch (e) {
      debugPrint('Error recording dose: $e');
      return false;
    }
  }

  /// Deletes a specific dose history item by ID.
  Future<bool> deleteDoseHistory(String id) async {
    try {
      final history = await getDoseHistory();
      history.removeWhere((item) => item.id == id);
      return await _saveHistoryList(history);
    } catch (e) {
      debugPrint('Error deleting dose history: $e');
      return false;
    }
  }

  /// Internal helper to persist the history list as JSON.
  Future<bool> _saveHistoryList(List<DoseHistory> history) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(history.map((h) => h.toJson()).toList());
    return await prefs.setString(_historyKey, jsonString);
  }

  /// Clears all stored data (medicines and dose histories) from local storage.
  Future<bool> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_medicinesKey);
      await prefs.remove(_historyKey);
      return true;
    } catch (e) {
      debugPrint('Error clearing local data: $e');
      return false;
    }
  }

  /// Seeds demo data for first-time onboarding or testing.
  Future<void> seedDemoDataIfEmpty() async {
    final medicines = await getMedicines();
    if (medicines.isNotEmpty) return;

    final now = DateTime.now();
    final demoMedicines = [
      Medicine(
        id: 'med_demo_1',
        name: 'Amoxicillin',
        dosage: '500 mg (1 capsule)',
        type: MedicineType.capsule,
        instructions: MedicineInstruction.afterFood,
        schedule: MedicineSchedule(
          frequency: MedicineFrequency.twiceDaily,
          reminderTimes: const ['08:00', '20:00'],
          startDate: DateTime(now.year, now.month, now.day - 2),
          endDate: DateTime(now.year, now.month, now.day + 5),
        ),
        notes: 'Take with a full glass of water. Finish entire antibiotic course.',
        isActive: true,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Medicine(
        id: 'med_demo_2',
        name: 'Cetirizine',
        dosage: '10 mg (1 tablet)',
        type: MedicineType.tablet,
        instructions: MedicineInstruction.beforeBed,
        schedule: MedicineSchedule(
          frequency: MedicineFrequency.onceDaily,
          reminderTimes: const ['21:30'],
          startDate: DateTime(now.year, now.month, now.day - 5),
          endDate: DateTime(now.year, now.month, now.day + 10),
        ),
        notes: 'For seasonal allergies. May cause mild drowsiness.',
        isActive: true,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Medicine(
        id: 'med_demo_3',
        name: 'Vitamin D3 & Calcium',
        dosage: '1 tablet',
        type: MedicineType.tablet,
        instructions: MedicineInstruction.withFood,
        schedule: MedicineSchedule(
          frequency: MedicineFrequency.onceDaily,
          reminderTimes: const ['09:00'],
          startDate: DateTime(now.year, now.month, now.day - 1),
          endDate: DateTime(now.year, now.month, now.day + 30),
        ),
        notes: 'Nutritional supplement. Take with breakfast.',
        isActive: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    for (final med in demoMedicines) {
      await saveMedicine(med);
    }
  }
}
