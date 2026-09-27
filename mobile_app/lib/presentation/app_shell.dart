import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../providers/providers.dart';
import 'screens/dashboard_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/fall_alert_overlay.dart';

/// Root shell widget with bottom navigation and alert overlay management.
///
/// Listens to the alert stream and triggers the full-screen
/// FallAlertOverlay when a fall is detected.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  final _screens = const [
    DashboardScreen(),
    AlertsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for alerts and show overlay
    ref.listen(alertStreamProvider, (previous, next) {
      next.whenData((alert) {
        if (alert.isFallDetected) {
          // Add to history
          ref.read(alertHistoryProvider.notifier).addAlert(alert);
          // Show overlay
          ref.read(activeAlertProvider.notifier).state = alert;
          ref.read(showAlertOverlayProvider.notifier).state = true;
        }
      });
    });

    final showOverlay = ref.watch(showAlertOverlayProvider);
    final activeAlert = ref.watch(activeAlertProvider);
    final alertHistory = ref.watch(alertHistoryProvider);
    final unreadCount =
        alertHistory.where((a) => !a.acknowledged).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main content
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Fall Alert Overlay
          if (showOverlay && activeAlert != null)
            Positioned.fill(
              child: FallAlertOverlay(
                alert: activeAlert,
                onAcknowledge: () {
                  ref.read(showAlertOverlayProvider.notifier).state = false;
                  ref.read(activeAlertProvider.notifier).state = null;
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              backgroundColor: AppColors.danger,
              child: const Icon(Icons.warning_amber_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              backgroundColor: AppColors.danger,
              child: const Icon(Icons.warning_amber),
            ),
            label: 'Alerts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
