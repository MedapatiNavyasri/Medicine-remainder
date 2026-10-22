import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../models/dose_history.dart';
import '../services/storage_service.dart';
import '../services/reminder_service.dart';
import '../utils/date_utils.dart';
import '../widgets/medicine_card.dart';
import '../widgets/empty_state.dart';
import 'add_medicine_screen.dart';
import 'medicine_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onNavigateToMedicines;

  const DashboardScreen({
    super.key,
    required this.onNavigateToMedicines,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StorageService _storageService = StorageService();
  final ReminderService _reminderService = ReminderService();

  List<Medicine> _medicines = [];
  List<DoseHistory> _history = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final meds = await _storageService.getMedicines();
      final hist = await _storageService.getDoseHistory();

      if (mounted) {
        setState(() {
          _medicines = meds;
          _history = hist;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load dashboard data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _recordDoseAction(ScheduledDose dose, String status) async {
    final now = DateTime.now();
    final doseRecord = DoseHistory(
      id: 'dose_${now.millisecondsSinceEpoch}',
      medicineId: dose.medicine.id,
      medicineName: dose.medicine.name,
      dosage: dose.medicine.dosage,
      scheduledDateTime: dose.scheduledDateTime,
      actionDateTime: now,
      status: status,
      notes: '',
    );

    final success = await _storageService.recordDose(doseRecord);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == DoseStatus.taken
                  ? 'Marked "${dose.medicine.name}" as taken.'
                  : 'Marked "${dose.medicine.name}" as skipped.',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _loadData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update dose status.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openAddMedicine() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddMedicineScreen(),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  void _openMedicineDetails(Medicine medicine) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => MedicineDetailsScreen(medicineId: medicine.id),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final metrics = _reminderService.calculateDashboardMetrics(
      medicines: _medicines,
      history: _history,
      referenceTime: now,
    );

    final todayDoses = _reminderService.getScheduledDosesForDate(
      targetDate: now,
      medicines: _medicines,
      history: _history,
      referenceTime: now,
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Greeting
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back 👋',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Today is ${AppDateUtils.formatDate(now)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _openAddMedicine,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Medicine'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Summary Metric Cards Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth < 600
                          ? 2
                          : (constraints.maxWidth < 900 ? 3 : 5);
                      return _buildMetricsGrid(metrics, crossAxisCount, theme);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Next Dose Highlight Banner (if available)
                  if (metrics.nextDose != null) ...[
                    _buildNextDoseBanner(metrics.nextDose!, theme),
                    const SizedBox(height: 24),
                  ],

                  // Today's Medicine Schedule Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's Schedule",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: widget.onNavigateToMedicines,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('All Medicines'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_medicines.isEmpty)
                    EmptyState(
                      icon: Icons.medication_outlined,
                      title: 'No medicines added yet',
                      message:
                          'Start keeping track of your daily doses by adding your prescribed medicines.',
                      buttonLabel: 'Add Your First Medicine',
                      buttonIcon: Icons.add,
                      onButtonPressed: _openAddMedicine,
                    )
                  else if (todayDoses.isEmpty)
                    EmptyState(
                      icon: Icons.event_available_outlined,
                      title: 'No doses scheduled for today',
                      message:
                          'You have no medications scheduled for today based on active date ranges.',
                      buttonLabel: 'View All Medicines',
                      buttonIcon: Icons.list_alt,
                      onButtonPressed: widget.onNavigateToMedicines,
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: todayDoses.length,
                      itemBuilder: (context, index) {
                        final dose = todayDoses[index];
                        return ScheduledDoseCard(
                          dose: dose,
                          onMarkTaken: () =>
                              _recordDoseAction(dose, DoseStatus.taken),
                          onMarkSkipped: () =>
                              _recordDoseAction(dose, DoseStatus.skipped),
                          onTap: () => _openMedicineDetails(dose.medicine),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddMedicine,
        icon: const Icon(Icons.add),
        label: const Text('Add Medicine'),
      ),
    );
  }

  Widget _buildMetricsGrid(
    DashboardMetrics metrics,
    int crossAxisCount,
    ThemeData theme,
  ) {
    final items = [
      _MetricData(
        title: 'Total Medicines',
        value: metrics.totalMedicines.toString(),
        icon: Icons.medication_rounded,
        color: const Color(0xFF00796B),
      ),
      _MetricData(
        title: 'Scheduled Today',
        value: metrics.scheduledTodayCount.toString(),
        icon: Icons.calendar_today_rounded,
        color: const Color(0xFF1565C0),
      ),
      _MetricData(
        title: 'Taken Today',
        value: metrics.takenTodayCount.toString(),
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF2E7D32),
      ),
      _MetricData(
        title: 'Upcoming',
        value: metrics.upcomingCount.toString(),
        icon: Icons.schedule_rounded,
        color: const Color(0xFF5E35B1),
      ),
      _MetricData(
        title: 'Missed / Pending',
        value: metrics.missedOrPendingCount.toString(),
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFC62828),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 12) /
            crossAxisCount;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return SizedBox(
              width: itemWidth,
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(item.icon, color: item.color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.value,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildNextDoseBanner(ScheduledDose nextDose, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'NEXT DOSE',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${AppDateUtils.formatTimeString(nextDose.timeString)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${nextDose.medicine.name} (${nextDose.medicine.dosage}) - ${nextDose.medicine.instructions}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () => _recordDoseAction(nextDose, DoseStatus.taken),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Take Now'),
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _MetricData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
