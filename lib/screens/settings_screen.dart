import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onDataChanged;

  const SettingsScreen({
    super.key,
    required this.onDataChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();

  int _medicinesCount = 0;
  int _historyCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    final meds = await _storageService.getMedicines();
    final hist = await _storageService.getDoseHistory();

    if (mounted) {
      setState(() {
        _medicinesCount = meds.length;
        _historyCount = hist.length;
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmClearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Application Data?'),
        content: const Text(
          'This will permanently delete all saved medicines, treatment schedules, '
          'and dose history from your browser local storage. This action cannot be reversed.',
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
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.clearAllData();
      await _loadStats();
      widget.onDataChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All local data cleared successfully.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _seedDemoData() async {
    await _storageService.seedDemoDataIfEmpty();
    await _loadStats();
    widget.onDataChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sample medications loaded successfully!'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Settings & System Info',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Application information, storage statistics, and platform notes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Card: App Information
                _buildCard(
                  theme,
                  title: 'About MediReminder',
                  icon: Icons.info_outline,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Color(0xFFE0F2F1),
                          child: Icon(Icons.medication, color: Color(0xFF00796B)),
                        ),
                        title: Text(
                          'MediReminder Web',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Version 1.0.0 • Developed with Dart & Flutter',
                        ),
                      ),
                      const Divider(height: 24),
                      Text(
                        'MediReminder is a lightweight, clean web application built to help individuals '
                        'track medication regimens, dosage frequencies, and daily dose compliance without '
                        'invasive ads or unnecessary complexity.',
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Card: Platform Notice & Browser Limitations
                _buildCard(
                  theme,
                  title: 'Web Platform & Reminder Notice',
                  icon: Icons.notifications_active_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFE082)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFF57F17),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Important Web Architecture Limitation: As a standard client-side Flutter Web '
                                'application, reminders and schedule calculations occur in-session. Web browsers '
                                'cannot run persistent background alarm daemons when the browser tab is closed '
                                'or the computer is shut down. MediReminder accurately calculates and tracks '
                                'all due, upcoming, and missed doses whenever you open or refresh the application.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.brown.shade800,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '• Due & Missed tracking: Handled inside the app on launch and during active sessions.\n'
                        '• Local persistence: Uses browser local storage (via shared_preferences) specific to this device and browser.',
                        style: TextStyle(fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Card: Storage Statistics & Data Management
                _buildCard(
                  theme,
                  title: 'Local Storage & Data Management',
                  icon: Icons.storage_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLoading)
                        const LinearProgressIndicator()
                      else
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Saved Medicines',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$_medicinesCount',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dose History Records',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$_historyCount',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1565C0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _seedDemoData,
                            icon: const Icon(Icons.dataset_outlined, size: 18),
                            label: const Text('Load Sample Demo Medicines'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _confirmClearData,
                            icon: const Icon(Icons.delete_forever, size: 18),
                            label: const Text('Clear All Local Data'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Medical Disclaimer Footer
                Center(
                  child: Text(
                    'MediReminder is a personal schedule and tracking tool. '
                    'It does not provide medical advice or prescribe treatments.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
