import 'package:flutter/material.dart';
import '../services/reminder_service.dart';

/// Reusable pill badge to indicate status of a dose or a medicine.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  /// Factory for DoseOccurrenceStatus (taken, skipped, due, missed, upcoming).
  factory StatusBadge.fromDoseStatus(DoseOccurrenceStatus status) {
    switch (status) {
      case DoseOccurrenceStatus.taken:
        return const StatusBadge(
          label: 'Taken',
          backgroundColor: Color(0xFFE8F5E9),
          textColor: Color(0xFF2E7D32),
          icon: Icons.check_circle_rounded,
        );
      case DoseOccurrenceStatus.skipped:
        return const StatusBadge(
          label: 'Skipped',
          backgroundColor: Color(0xFFFFF3E0),
          textColor: Color(0xFFE65100),
          icon: Icons.do_not_disturb_on_rounded,
        );
      case DoseOccurrenceStatus.due:
        return const StatusBadge(
          label: 'Due Now',
          backgroundColor: Color(0xFFFFF8E1),
          textColor: Color(0xFFF57F17),
          icon: Icons.alarm_on_rounded,
        );
      case DoseOccurrenceStatus.missed:
        return const StatusBadge(
          label: 'Missed',
          backgroundColor: Color(0xFFFFEBEE),
          textColor: Color(0xFFC62828),
          icon: Icons.error_outline_rounded,
        );
      case DoseOccurrenceStatus.upcoming:
        return const StatusBadge(
          label: 'Upcoming',
          backgroundColor: Color(0xFFE3F2FD),
          textColor: Color(0xFF1565C0),
          icon: Icons.schedule_rounded,
        );
    }
  }

  /// Factory for medicine active/inactive status.
  factory StatusBadge.medicineActive(bool isActive) {
    if (isActive) {
      return const StatusBadge(
        label: 'Active',
        backgroundColor: Color(0xFFE8F5E9),
        textColor: Color(0xFF2E7D32),
        icon: Icons.check_rounded,
      );
    } else {
      return const StatusBadge(
        label: 'Completed / Inactive',
        backgroundColor: Color(0xFFECEFF1),
        textColor: Color(0xFF546E7A),
        icon: Icons.done_all_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: textColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: textColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
