import 'package:flutter/material.dart';

/// Supported frequencies for medication reminders.
class MedicineFrequency {
  static const String onceDaily = 'Once daily';
  static const String twiceDaily = 'Twice daily';
  static const String threeTimesDaily = 'Three times daily';
  static const String custom = 'Custom';

  static const List<String> all = [
    onceDaily,
    twiceDaily,
    threeTimesDaily,
    custom,
  ];

  /// Default times suggested for standard frequencies.
  static List<String> defaultTimesFor(String frequency) {
    switch (frequency) {
      case onceDaily:
        return ['08:00'];
      case twiceDaily:
        return ['08:00', '20:00'];
      case threeTimesDaily:
        return ['08:00', '14:00', '20:00'];
      default:
        return ['08:00'];
    }
  }
}

/// Supported medicine dosage forms/types.
class MedicineType {
  static const String tablet = 'Tablet';
  static const String capsule = 'Capsule';
  static const String syrup = 'Syrup';
  static const String injection = 'Injection';
  static const String drops = 'Drops';
  static const String inhaler = 'Inhaler';
  static const String topical = 'Topical / Cream';
  static const String other = 'Other';

  static const List<String> all = [
    tablet,
    capsule,
    syrup,
    injection,
    drops,
    inhaler,
    topical,
    other,
  ];

  static IconData iconFor(String type) {
    switch (type) {
      case tablet:
        return Icons.medication;
      case capsule:
        return Icons.medical_services_outlined;
      case syrup:
        return Icons.local_drink_outlined;
      case injection:
        return Icons.vaccines_outlined;
      case drops:
        return Icons.water_drop_outlined;
      case inhaler:
        return Icons.air_outlined;
      case topical:
        return Icons.clean_hands_outlined;
      default:
        return Icons.healing_outlined;
    }
  }
}

/// Food intake instructions.
class MedicineInstruction {
  static const String beforeFood = 'Before food';
  static const String afterFood = 'After food';
  static const String withFood = 'With food';
  static const String emptyStomach = 'Empty stomach';
  static const String beforeBed = 'Before bed';
  static const String anytime = 'Anytime / As needed';

  static const List<String> all = [
    beforeFood,
    afterFood,
    withFood,
    emptyStomach,
    beforeBed,
    anytime,
  ];
}

/// Schedule configuration for a medicine.
class MedicineSchedule {
  final String frequency; // e.g. "Once daily", "Twice daily", "Custom"
  final List<String> reminderTimes; // 24-hr format "HH:mm", e.g. ["08:00", "20:00"]
  final DateTime startDate;
  final DateTime endDate;

  const MedicineSchedule({
    required this.frequency,
    required this.reminderTimes,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency,
      'reminderTimes': reminderTimes,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  factory MedicineSchedule.fromJson(Map<String, dynamic> json) {
    final timesRaw = json['reminderTimes'];
    List<String> parsedTimes = [];
    if (timesRaw is List) {
      parsedTimes = timesRaw.map((e) => e.toString()).toList();
    }
    if (parsedTimes.isEmpty) {
      parsedTimes = ['08:00'];
    }

    return MedicineSchedule(
      frequency: json['frequency']?.toString() ?? MedicineFrequency.onceDaily,
      reminderTimes: parsedTimes,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString()) ??
              DateTime.now().add(const Duration(days: 7))
          : DateTime.now().add(const Duration(days: 7)),
    );
  }

  MedicineSchedule copyWith({
    String? frequency,
    List<String>? reminderTimes,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return MedicineSchedule(
      frequency: frequency ?? this.frequency,
      reminderTimes: reminderTimes ?? List.from(this.reminderTimes),
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

/// Primary model representing a medication.
class Medicine {
  final String id;
  final String name;
  final String dosage; // e.g. "1 tablet", "5 ml"
  final String type; // e.g. Tablet, Syrup, etc.
  final String instructions; // e.g. Before food, After food
  final MedicineSchedule schedule;
  final String notes;
  final bool isActive;
  final DateTime createdAt;

  const Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.type,
    required this.instructions,
    required this.schedule,
    this.notes = '',
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'type': type,
      'instructions': instructions,
      'schedule': schedule.toJson(),
      'notes': notes,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Medicine',
      dosage: json['dosage']?.toString() ?? '1 dose',
      type: json['type']?.toString() ?? MedicineType.tablet,
      instructions: json['instructions']?.toString() ?? MedicineInstruction.afterFood,
      schedule: json['schedule'] != null && json['schedule'] is Map<String, dynamic>
          ? MedicineSchedule.fromJson(json['schedule'] as Map<String, dynamic>)
          : MedicineSchedule(
              frequency: MedicineFrequency.onceDaily,
              reminderTimes: const ['08:00'],
              startDate: DateTime.now(),
              endDate: DateTime.now().add(const Duration(days: 7)),
            ),
      notes: json['notes']?.toString() ?? '',
      isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Medicine copyWith({
    String? id,
    String? name,
    String? dosage,
    String? type,
    String? instructions,
    MedicineSchedule? schedule,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      type: type ?? this.type,
      instructions: instructions ?? this.instructions,
      schedule: schedule ?? this.schedule,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
