import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../models/dose_history.dart';
import '../services/storage_service.dart';
import '../utils/date_utils.dart';
import '../widgets/empty_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final StorageService _storageService = StorageService();

  List<DoseHistory> _allHistory = [];
  List<Medicine> _allMedicines = [];
  bool _isLoading = true;

  String _selectedMedicineId = 'all';
  String _selectedStatus = 'all';
  DateTime? _selectedFilterDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final hist = await _storageService.getDoseHistory();
    final meds = await _storageService.getMedicines();

    if (mounted) {
      setState(() {
        _allHistory = hist;
        _allMedicines = meds;
        _isLoading = false;
      });
    }
  }

  List<DoseHistory> get _filteredHistory {
    return _allHistory.where((item) {
      // Filter by medicine
      if (_selectedMedicineId != 'all' && item.medicineId != _selectedMedicineId) {
        return false;
      }

      // Filter by status
      if (_selectedStatus != 'all' &&
          item.status.toLowerCase() != _selectedStatus.toLowerCase()) {
        return false;
      }

      // Filter by date
      if (_selectedFilterDate != null) {
        if (!AppDateUtils.isSameDay(item.scheduledDateTime, _selectedFilterDate!)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _pickFilterDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedFilterDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Filter history by date',
    );

    if (picked != null) {
      setState(() {
        _selectedFilterDate = picked;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedMedicineId = 'all';
      _selectedStatus = 'all';
      _selectedFilterDate = null;
    });
  }

  Future<void> _deleteRecord(DoseHistory item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Dose Record?'),
        content: Text(
          'Remove this record for ${item.medicineName} (${AppDateUtils.formatDateTime(item.scheduledDateTime)})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.deleteDoseHistory(item.id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayedList = _filteredHistory;

    // Statistics calculations
    final totalCount = displayedList.length;
    final takenCount = displayedList.where((h) => h.status == DoseStatus.taken).length;
    final skippedCount = displayedList.where((h) => h.status == DoseStatus.skipped).length;
    final adherenceRate = totalCount > 0
        ? ((takenCount / totalCount) * 100).toStringAsFixed(0)
        : '0';

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Dose History',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review and audit previously recorded medicine intakes and skipped doses',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),

                // Adherence Statistics Bar
                if (_allHistory.isNotEmpty) ...[
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          _buildStatItem(
                            theme,
                            label: 'Total Logs',
                            value: totalCount.toString(),
                            icon: Icons.list_alt,
                            color: theme.colorScheme.primary,
                          ),
                          _buildVerticalDivider(),
                          _buildStatItem(
                            theme,
                            label: 'Taken',
                            value: takenCount.toString(),
                            icon: Icons.check_circle_outline,
                            color: const Color(0xFF2E7D32),
                          ),
                          _buildVerticalDivider(),
                          _buildStatItem(
                            theme,
                            label: 'Skipped',
                            value: skippedCount.toString(),
                            icon: Icons.do_not_disturb_on_outlined,
                            color: const Color(0xFFE65100),
                          ),
                          _buildVerticalDivider(),
                          _buildStatItem(
                            theme,
                            label: 'Adherence',
                            value: '$adherenceRate%',
                            icon: Icons.pie_chart_outline,
                            color: const Color(0xFF1565C0),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Filter Controls Row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                // Medicine Dropdown
                                SizedBox(
                                  width: isNarrow ? constraints.maxWidth : 220,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedMedicineId,
                                    isDense: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Medicine',
                                      prefixIcon: Icon(Icons.medication, size: 18),
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 10,
                                      ),
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: 'all',
                                        child: Text('All Medicines'),
                                      ),
                                      ..._allMedicines.map((m) {
                                        return DropdownMenuItem(
                                          value: m.id,
                                          child: Text(
                                            m.name,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedMedicineId = val;
                                        });
                                      }
                                    },
                                  ),
                                ),

                                // Status Dropdown
                                SizedBox(
                                  width: isNarrow ? constraints.maxWidth : 160,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedStatus,
                                    isDense: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Status',
                                      prefixIcon: Icon(Icons.filter_alt_outlined, size: 18),
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 10,
                                      ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                                      DropdownMenuItem(value: 'taken', child: Text('Taken')),
                                      DropdownMenuItem(value: 'skipped', child: Text('Skipped')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedStatus = val;
                                        });
                                      }
                                    },
                                  ),
                                ),

                                // Date Filter Chip / Button
                                OutlinedButton.icon(
                                  onPressed: _pickFilterDate,
                                  icon: const Icon(Icons.calendar_month, size: 16),
                                  label: Text(
                                    _selectedFilterDate != null
                                        ? AppDateUtils.formatDate(_selectedFilterDate)
                                        : 'Select Date',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),

                                // Reset filters button
                                if (_selectedMedicineId != 'all' ||
                                    _selectedStatus != 'all' ||
                                    _selectedFilterDate != null)
                                  TextButton.icon(
                                    onPressed: _clearFilters,
                                    icon: const Icon(Icons.clear_all, size: 18),
                                    label: const Text('Reset Filters'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // History List or Empty State
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : displayedList.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              itemCount: displayedList.length,
                              itemBuilder: (context, index) {
                                final item = displayedList[index];
                                return _buildHistoryItem(item, theme);
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(DoseHistory item, ThemeData theme) {
    final isTaken = item.status == DoseStatus.taken;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isTaken
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isTaken
                    ? Icons.check_circle_outline
                    : Icons.do_not_disturb_on_outlined,
                color: isTaken
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFE65100),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.medicineName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
                          item.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dosage: ${item.dosage}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Scheduled: ${AppDateUtils.formatDateTime(item.scheduledDateTime)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Action taken: ${AppDateUtils.formatDateTime(item.actionDateTime)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: Colors.grey.shade600,
              tooltip: 'Delete history record',
              onPressed: () => _deleteRecord(item),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildEmptyState() {
    if (_allHistory.isEmpty) {
      return const EmptyState(
        icon: Icons.history_rounded,
        title: 'No dose records yet',
        message:
            'When you mark scheduled doses as "Taken" or "Skipped" on the dashboard, they will be tracked here.',
      );
    }

    return EmptyState(
      icon: Icons.filter_alt_off_outlined,
      title: 'No matching records',
      message: 'No dose history records match the current filter selection.',
      buttonLabel: 'Reset Filters',
      buttonIcon: Icons.refresh,
      onButtonPressed: _clearFilters,
    );
  }
}
