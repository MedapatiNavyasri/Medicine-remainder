import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/storage_service.dart';
import '../widgets/medicine_card.dart';
import '../widgets/empty_state.dart';
import 'add_medicine_screen.dart';
import 'medicine_details_screen.dart';

class MedicineListScreen extends StatefulWidget {
  const MedicineListScreen({super.key});

  @override
  State<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  final StorageService _storageService = StorageService();

  List<Medicine> _allMedicines = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'Active', 'Completed'

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicines() async {
    setState(() {
      _isLoading = true;
    });

    final meds = await _storageService.getMedicines();
    if (mounted) {
      setState(() {
        _allMedicines = meds;
        _isLoading = false;
      });
    }
  }

  List<Medicine> get _filteredMedicines {
    return _allMedicines.where((med) {
      // Filter by search query
      final matchesSearch = _searchQuery.isEmpty ||
          med.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          med.dosage.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          med.type.toLowerCase().contains(_searchQuery.toLowerCase());

      // Filter by status
      bool matchesStatus = true;
      if (_statusFilter == 'Active') {
        matchesStatus = med.isActive;
      } else if (_statusFilter == 'Completed') {
        matchesStatus = !med.isActive;
      }

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _toggleMedicineActive(Medicine medicine, bool newStatus) async {
    final success = await _storageService.toggleMedicineStatus(medicine.id, newStatus);
    if (success) {
      _loadMedicines();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? 'Marked "${medicine.name}" as active.'
                  : 'Marked "${medicine.name}" as completed / inactive.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteMedicine(Medicine medicine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine?'),
        content: Text(
          'Are you sure you want to permanently delete "${medicine.name}"? '
          'This action cannot be undone. Previous dose history for this medicine will be preserved.',
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
      final success = await _storageService.deleteMedicine(medicine.id);
      if (success) {
        _loadMedicines();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted "${medicine.name}".'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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
      _loadMedicines();
    }
  }

  void _openEditMedicine(Medicine medicine) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddMedicineScreen(medicineToEdit: medicine),
      ),
    );

    if (result == true) {
      _loadMedicines();
    }
  }

  void _openDetails(Medicine medicine) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => MedicineDetailsScreen(medicineId: medicine.id),
      ),
    );

    if (result == true) {
      _loadMedicines();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayedList = _filteredMedicines;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Add Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Medicines',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your medication schedules and prescriptions',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _openAddMedicine,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Medicine'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search & Filter Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search medicines by name or dosage...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', _allMedicines.length),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Active',
                        _allMedicines.where((m) => m.isActive).length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Completed',
                        _allMedicines.where((m) => !m.isActive).length,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Medicines List or Empty State
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : displayedList.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              itemCount: displayedList.length,
                              itemBuilder: (context, index) {
                                final med = displayedList[index];
                                return MedicineCard(
                                  medicine: med,
                                  onTap: () => _openDetails(med),
                                  onEdit: () => _openEditMedicine(med),
                                  onDelete: () => _deleteMedicine(med),
                                  onToggleActive: (val) =>
                                      _toggleMedicineActive(med, val),
                                );
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

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _statusFilter == label;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _statusFilter = label;
          });
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_allMedicines.isEmpty) {
      return EmptyState(
        icon: Icons.medication_outlined,
        title: 'No medicines added yet',
        message: 'Tap "Add Medicine" to create your first prescription reminder.',
        buttonLabel: 'Add Medicine',
        onButtonPressed: _openAddMedicine,
      );
    }

    return EmptyState(
      icon: Icons.search_off_rounded,
      title: 'No matching medicines found',
      message: 'Try adjusting your search terms or filter selection.',
      buttonLabel: 'Clear Filters',
      buttonIcon: Icons.refresh,
      onButtonPressed: () {
        _searchController.clear();
        setState(() {
          _searchQuery = '';
          _statusFilter = 'All';
        });
      },
    );
  }
}
