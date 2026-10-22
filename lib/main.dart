import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/medicine_list_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MediReminderApp());
}

class MediReminderApp extends StatelessWidget {
  const MediReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF00796B);

    return MaterialApp(
      title: 'MediReminder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryTeal,
          primary: primaryTeal,
          surface: const Color(0xFFFFFFFF),
          surfaceContainerLowest: const Color(0xFFFFFFFF),
          surfaceContainerLow: const Color(0xFFF8FAFC),
          surfaceContainer: const Color(0xFFF1F5F9),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFFFFFFFF),
          foregroundColor: Color(0xFF1E293B),
          centerTitle: false,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFFFFFFFF),
          surfaceTintColor: Colors.transparent,
        ),
        fontFamily: null, // Uses system font with crisp fallback
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;
  int _refreshKey = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onDataChanged() {
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // List of navigation destinations
    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard_rounded),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(Icons.medication_outlined),
        selectedIcon: Icon(Icons.medication_rounded),
        label: 'Medicines',
      ),
      const NavigationDestination(
        icon: Icon(Icons.history_outlined),
        selectedIcon: Icon(Icons.history_rounded),
        label: 'History',
      ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings_rounded),
        label: 'Settings',
      ),
    ];

    // Build the screen for current index
    Widget currentScreen;
    switch (_selectedIndex) {
      case 0:
        currentScreen = DashboardScreen(
          key: ValueKey('dashboard_$_refreshKey'),
          onNavigateToMedicines: () => _onItemTapped(1),
        );
        break;
      case 1:
        currentScreen = MedicineListScreen(
          key: ValueKey('medicines_$_refreshKey'),
        );
        break;
      case 2:
        currentScreen = HistoryScreen(
          key: ValueKey('history_$_refreshKey'),
        );
        break;
      case 3:
        currentScreen = SettingsScreen(
          key: ValueKey('settings_$_refreshKey'),
          onDataChanged: _onDataChanged,
        );
        break;
      default:
        currentScreen = DashboardScreen(
          key: ValueKey('dashboard_$_refreshKey'),
          onNavigateToMedicines: () => _onItemTapped(1),
        );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        if (isDesktop) {
          // Desktop / Tablet layout with NavigationRail
          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.medication_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'MediReminder',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  height: 1,
                ),
              ),
            ),
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  labelType: NavigationRailLabelType.all,
                  leading: const SizedBox(height: 8),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.medication_outlined),
                      selectedIcon: Icon(Icons.medication_rounded),
                      label: Text('Medicines'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.history_outlined),
                      selectedIcon: Icon(Icons.history_rounded),
                      label: Text('History'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings_rounded),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: currentScreen),
              ],
            ),
          );
        }

        // Mobile layout with bottom NavigationBar
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.medication_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'MediReminder',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                height: 1,
              ),
            ),
          ),
          body: currentScreen,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            destinations: destinations,
          ),
        );
      },
    );
  }
}
