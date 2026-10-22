import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../models/dose_history.dart';
import '../services/storage_service.dart';
import '../utils/date_utils.dart';
import '../widgets/status_badge.dart';
import '../widgets/empty_state.dart';
import 'add_medicine_screen.dart';

class MedicineDetailsScreen extends StatefulWidget {
  final String medicineId;

  const MedicineDetailsScreen({
    super.key,
    required this.medicineId,
  });

  @override
  State<MedicineDetailsScreen> createState() => _MedicineDetailsScreenState();
}

class _MedicineDetailsScreenState extends State<MedicineDetailsScreen> {
  final StorageService _storageService = StorageService();

  Medicine? _medicine;
  List<DoseHistory> _medicineHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedicineDetails();
  }

  Future<void> _loadMedicineDetails() async {
    setState(() {
      _isLoading = true;
    });

    final meds = await _storageService.getMedicines();
    final hist = await _storageService.getDoseHistory();

    final found = meds.where((m) => m.id == widget.medicineId).firstOrNull;
    final filteredHistory = hist
        .where((h) => h.medicineId == widget.medicineId)
        .toList();

    if (mounted) {
      setState(() {
        _medicine = found;
        _medicineHistory = filteredHistory;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleActive() async {
    if (_medicine == null) return;
    final newStatus = !_medicine!.isActive;
    final success = await _storageService.toggleMedicineStatus(
      _medicine!.id,
      newStatus,
    );
    if (success) {
      _loadMedicineDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? 'Medication marked as active.'
                  : 'Medication marked as completed / inactive.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _editMedicine() async {
    if (_medicine == null) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddMedicineScreen(medicineToEdit: _medicine),
      ),
    );

    if (result == true) {
      _loadMedicineDetails();
    }
  }

  Future<void> _deleteMedicine() async {
    if (_medicine == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine?'),
        content: Text(
          'Are you sure you want to permanently delete "${_medicine!.name}"? '
          'Existing dose records will remain saved in your history log.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _storageService.deleteMedicine(_medicine!.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${_medicine!.name}".'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Medicine Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_medicine == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Medicine Details')),
        body: EmptyState(
          icon: Icons.error_outline,
          title: 'Medicine Not Found',
          message: 'The requested medicine may have been deleted.',
          buttonLabel: 'Go Back',
          buttonIcon: Icons.arrow_back,
          onButtonPressed: () => Navigator.of(context).pop(),
        ),
      );
    }

    final med = _medicine!;
    final now = DateTime.now();
    final remainingDays =
        AppDateUtils.dateOnly(med.schedule.endDate).difference(AppDateUtils.dateOnly(now)).inDays;

    return Scaffold(
      appBar: AppBar(
        title: Text(med.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit medicine',
            onPressed: _editMedicine,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete medicine',
            onPressed: _deleteMedicine,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Hero Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                MedicineType.iconFor(med.type),
                                color: theme.colorScheme.primary,
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          med.name,
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      StatusBadge.medicineActive(med.isActive),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${med.dosage} • ${med.type}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              med.isActive
                                  ? 'Active Treatment Schedule'
                                  : 'Schedule Completed / Paused',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _toggleActive,
                              icon: Icon(
                                med.isActive
                                    ? Icons.pause_circle_outline
                                    : Icons.play_circle_outline,
                                size: 16,
                              ),
                              label: Text(
                                med.isActive ? 'Mark Inactive' : 'Mark Active',
                              ),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Details Grid
                Text(
                  'Schedule & Instructions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildDetailTile(
                          context,
                          title: 'Frequency',
                          value: med.schedule.frequency,
                          icon: Icons.repeat_rounded,
                          width: isNarrow
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 12) / 2,
                        ),
                        _buildDetailTile(
                          context,
                          title: 'Instructions',
                          value: med.instructions,
                          icon: Icons.restaurant_outlined,
                          width: isNarrow
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 12) / 2,
                        ),
                        _buildDetailTile(
                          context,
                          title: 'Start Date',
                          value: AppDateUtils.formatDate(med.schedule.startDate),
                          icon: Icons.calendar_today_outlined,
                          width: isNarrow
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 12) / 2,
                        ),
                        _buildDetailTile(
                          context,
                          title: 'End Date',
                          value:
                              '${AppDateUtils.formatDate(med.schedule.endDate)} (${remainingDays >= 0 ? '$remainingDays days left' : 'Ended'})',
                          icon: Icons.event_available_outlined,
                          width: isNarrow
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 12) / 2,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Reminder Times Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.alarm_rounded,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Configured Reminder Times',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: med.schedule.reminderTimes.map((time) {
                            return Chip(
                              avatar: const Icon(Icons.access_time_filled, size: 16),
                              label: Text(
                                AppDateUtils.formatTimeString(time),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Notes Card
                if (med.notes.trim().isNotEmpty) ...[
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.notes_rounded,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Notes & Warnings',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            med.notes,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Dose History For This Medicine
                Text(
                  'Recent Dose History (${_medicineHistory.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                if (_medicineHistory.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'No doses recorded yet for this medicine.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _medicineHistory.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final record = _medicineHistory[index];
                      final isTaken = record.status == DoseStatus.taken;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isTaken
                              ? const Color(0xFFE8F5E9).withValues(alpha: 0.5)
                              : const Color(0xFFFFF3E0).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isTaken
                                ? const Color(0xFFC8E6C9)
                                : const Color(0xFFFFE0B2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isTaken
                                  ? Icons.check_circle_rounded
                                  : Icons.do_not_disturb_on_rounded,
                              size: 18,
                              color: isTaken
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFE65100),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Scheduled: ${AppDateUtils.formatDateTime(record.scheduledDateTime)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'Action taken at ${AppDateUtils.formatDateTime(record.actionDateTime)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isTaken
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFE65100),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                record.status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required double width,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
