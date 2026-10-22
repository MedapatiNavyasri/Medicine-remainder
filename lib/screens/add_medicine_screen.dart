import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/storage_service.dart';
import '../utils/date_utils.dart';
import '../utils/validators.dart';

class AddMedicineScreen extends StatefulWidget {
  final Medicine? medicineToEdit;

  const AddMedicineScreen({
    super.key,
    this.medicineToEdit,
  });

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storageService = StorageService();

  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _notesController;

  late String _selectedType;
  late String _selectedInstruction;
  late String _selectedFrequency;
  late List<String> _reminderTimes;
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _isActive;

  String? _dateRangeError;
  String? _reminderTimesError;
  bool _isSaving = false;

  bool get _isEditing => widget.medicineToEdit != null;

  @override
  void initState() {
    super.initState();
    final med = widget.medicineToEdit;
    final now = DateTime.now();

    _nameController = TextEditingController(text: med?.name ?? '');
    _dosageController = TextEditingController(text: med?.dosage ?? '');
    _notesController = TextEditingController(text: med?.notes ?? '');

    _selectedType = med?.type ?? MedicineType.tablet;
    _selectedInstruction = med?.instructions ?? MedicineInstruction.afterFood;
    _selectedFrequency = med?.schedule.frequency ?? MedicineFrequency.onceDaily;

    if (med != null) {
      _reminderTimes = List<String>.from(med.schedule.reminderTimes);
      _startDate = med.schedule.startDate;
      _endDate = med.schedule.endDate;
      _isActive = med.isActive;
    } else {
      _reminderTimes =
          List<String>.from(MedicineFrequency.defaultTimesFor(_selectedFrequency));
      _startDate = AppDateUtils.dateOnly(now);
      _endDate = AppDateUtils.dateOnly(now.add(const Duration(days: 7)));
      _isActive = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onFrequencyChanged(String? newFrequency) {
    if (newFrequency == null) return;
    setState(() {
      _selectedFrequency = newFrequency;
      if (newFrequency != MedicineFrequency.custom) {
        _reminderTimes = List<String>.from(
          MedicineFrequency.defaultTimesFor(newFrequency),
        );
      }
      _reminderTimesError = null;
    });
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Select medication start date',
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        _validateDates();
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Select medication end date',
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
        _validateDates();
      });
    }
  }

  void _validateDates() {
    setState(() {
      _dateRangeError = Validators.dateRange(_startDate, _endDate);
    });
  }

  Future<void> _addOrEditReminderTime({int? index}) async {
    final initialTime = index != null && index < _reminderTimes.length
        ? AppDateUtils.stringToTimeOfDay(_reminderTimes[index])
        : const TimeOfDay(hour: 8, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: index != null ? 'Edit reminder time' : 'Select reminder time',
    );

    if (picked != null) {
      final formatted = AppDateUtils.timeOfDayToString(picked);
      setState(() {
        if (index != null) {
          _reminderTimes[index] = formatted;
        } else {
          if (!_reminderTimes.contains(formatted)) {
            _reminderTimes.add(formatted);
            _reminderTimes.sort();
          }
        }
        _reminderTimesError = Validators.reminderTimes(_reminderTimes);
      });
    }
  }

  void _removeReminderTime(int index) {
    setState(() {
      _reminderTimes.removeAt(index);
      _reminderTimesError = Validators.reminderTimes(_reminderTimes);
    });
  }

  Future<void> _saveMedicine() async {
    _validateDates();
    final timesError = Validators.reminderTimes(_reminderTimes);
    setState(() {
      _reminderTimesError = timesError;
    });

    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid || _dateRangeError != null || _reminderTimesError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the highlighted errors in the form.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now();
      final id = widget.medicineToEdit?.id ??
          'med_${now.microsecondsSinceEpoch}';

      final medicine = Medicine(
        id: id,
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        type: _selectedType,
        instructions: _selectedInstruction,
        schedule: MedicineSchedule(
          frequency: _selectedFrequency,
          reminderTimes: _reminderTimes,
          startDate: _startDate,
          endDate: _endDate,
        ),
        notes: _notesController.text.trim(),
        isActive: _isActive,
        createdAt: widget.medicineToEdit?.createdAt ?? now,
      );

      final success = await _storageService.saveMedicine(medicine);

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'Medicine "${medicine.name}" updated successfully!'
                    : 'Medicine "${medicine.name}" saved successfully!',
              ),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save medicine to storage.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Medicine' : 'Add New Medicine'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section: Basic Info
                  _buildSectionHeader(
                    theme,
                    title: 'General Information',
                    subtitle: 'Enter the medicine name, dosage, and form',
                    icon: Icons.medication_outlined,
                  ),
                  const SizedBox(height: 16),

                  // Medicine Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Medicine Name *',
                      hintText: 'e.g. Paracetamol, Amoxicillin, Lipitor',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.medicineName,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Dosage & Type Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 500;
                      if (isNarrow) {
                        return Column(
                          children: [
                            _buildDosageField(),
                            const SizedBox(height: 16),
                            _buildTypeDropdown(),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildDosageField()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTypeDropdown()),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Instructions
                  DropdownButtonFormField<String>(
                    initialValue: _selectedInstruction,
                    decoration: const InputDecoration(
                      labelText: 'Intake Instructions *',
                      prefixIcon: Icon(Icons.restaurant_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: MedicineInstruction.all.map((instruction) {
                      return DropdownMenuItem(
                        value: instruction,
                        child: Text(instruction),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedInstruction = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 32),

                  // Section: Schedule & Reminders
                  _buildSectionHeader(
                    theme,
                    title: 'Schedule & Reminders',
                    subtitle: 'Define frequency, reminder times, and treatment duration',
                    icon: Icons.alarm_outlined,
                  ),
                  const SizedBox(height: 16),

                  // Frequency Selector
                  DropdownButtonFormField<String>(
                    initialValue: _selectedFrequency,
                    decoration: const InputDecoration(
                      labelText: 'Reminder Frequency *',
                      prefixIcon: Icon(Icons.repeat_rounded),
                      border: OutlineInputBorder(),
                    ),
                    items: MedicineFrequency.all.map((freq) {
                      return DropdownMenuItem(
                        value: freq,
                        child: Text(freq),
                      );
                    }).toList(),
                    onChanged: _onFrequencyChanged,
                  ),
                  const SizedBox(height: 16),

                  // Reminder Times list
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: _reminderTimesError != null
                            ? Colors.red
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Reminder Times (${_reminderTimes.length})',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _addOrEditReminderTime(),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Time'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_reminderTimes.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No reminder times added. Please add at least one.',
                                style: TextStyle(color: Colors.red),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(_reminderTimes.length, (i) {
                                final timeStr = _reminderTimes[i];
                                return Chip(
                                  avatar: const Icon(
                                    Icons.access_time_filled,
                                    size: 16,
                                  ),
                                  label: Text(
                                    AppDateUtils.formatTimeString(timeStr),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  onDeleted: _reminderTimes.length > 1
                                      ? () => _removeReminderTime(i)
                                      : null,
                                  deleteIconColor: Colors.grey.shade600,
                                );
                              }),
                            ),
                          if (_reminderTimesError != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _reminderTimesError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date Range Pickers (Start Date & End Date)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 500;
                      if (isNarrow) {
                        return Column(
                          children: [
                            _buildDateTile(
                              title: 'Start Date *',
                              date: _startDate,
                              onTap: _selectStartDate,
                              theme: theme,
                            ),
                            const SizedBox(height: 12),
                            _buildDateTile(
                              title: 'End Date *',
                              date: _endDate,
                              onTap: _selectEndDate,
                              theme: theme,
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: _buildDateTile(
                              title: 'Start Date *',
                              date: _startDate,
                              onTap: _selectStartDate,
                              theme: theme,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDateTile(
                              title: 'End Date *',
                              date: _endDate,
                              onTap: _selectEndDate,
                              theme: theme,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  if (_dateRangeError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _dateRangeError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Section: Notes & Status
                  _buildSectionHeader(
                    theme,
                    title: 'Additional Details',
                    subtitle: 'Optional physician notes, side effects, and active state',
                    icon: Icons.notes_outlined,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes & Instructions (Optional)',
                      hintText:
                          'e.g. Take with a large glass of water. Avoid alcohol. Complete full 7-day course.',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Active / Inactive switch
                  SwitchListTile(
                    title: const Text('Medication is currently active'),
                    subtitle: Text(
                      _isActive
                          ? 'This medicine will generate active reminders and appear on dashboard.'
                          : 'Reminders are paused. Medicine is marked as completed/inactive.',
                    ),
                    value: _isActive,
                    onChanged: (val) {
                      setState(() {
                        _isActive = val;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 32),

                  // Submit & Cancel Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveMedicine,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(_isEditing ? 'Update Medicine' : 'Save Medicine'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDosageField() {
    return TextFormField(
      controller: _dosageController,
      decoration: const InputDecoration(
        labelText: 'Dosage *',
        hintText: 'e.g. 1 tablet, 500 mg, 10 ml',
        prefixIcon: Icon(Icons.straighten_outlined),
        border: OutlineInputBorder(),
      ),
      validator: Validators.dosage,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedType,
      decoration: const InputDecoration(
        labelText: 'Medicine Type *',
        prefixIcon: Icon(Icons.category_outlined),
        border: OutlineInputBorder(),
      ),
      items: MedicineType.all.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(MedicineType.iconFor(type), size: 18),
              const SizedBox(width: 8),
              Text(type),
            ],
          ),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedType = val;
          });
        }
      },
    );
  }

  Widget _buildDateTile({
    required String title,
    required DateTime date,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
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
                  AppDateUtils.formatDate(date),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.calendar_month_outlined,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
