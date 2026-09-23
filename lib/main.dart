import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'repositories/local_dose_repository.dart';
import 'repositories/dose_repository.dart';
import 'services/notification_service.dart';
import 'providers/today_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/history_provider.dart';
import 'screens/today_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final notifService = NotificationService();
  await notifService.initialize();

  final repo = LocalDoseRepository();

  runApp(
    MultiProvider(
      providers: [
        // Expose the repository and notification service
        Provider<DoseRepository>(create: (_) => repo),
        Provider<LocalDoseRepository>(create: (_) => repo),
        Provider<NotificationService>(create: (_) => notifService),

        // Feature providers
        ChangeNotifierProvider(
          create: (ctx) => TodayProvider(
            ctx.read<DoseRepository>(),
            ctx.read<NotificationService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) =>
              ScheduleProvider(ctx.read<DoseRepository>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) =>
              HistoryProvider(ctx.read<DoseRepository>()),
        ),
      ],
      child: const MedTrackApp(),
    ),
  );
}

class MedTrackApp extends StatelessWidget {
  const MedTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _titles = ['Today', 'Schedule', 'History', 'Settings'];

  final _screens = const [
    TodayScreen(),
    ScheduleScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.medication, size: 22),
            const SizedBox(width: 8),
            Text(_titles[_currentIndex]),
          ],
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh today',
              onPressed: () =>
                  context.read<TodayProvider>().loadToday(),
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          // Reload the history tab when navigating to it
          if (i == 2) {
            final compartments =
                context.read<ScheduleProvider>().compartments;
            context.read<HistoryProvider>().load(compartments);
          }
        },
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.teal.withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppTheme.teal),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon:
                Icon(Icons.calendar_today, color: AppTheme.teal),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: AppTheme.teal),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: AppTheme.teal),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
