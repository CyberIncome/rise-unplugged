import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/alarms/widgets/alarm_dashboard.dart';
import '../../features/sleep_debt/widgets/sleep_debt_dashboard.dart';
import '../../features/unplug_timer/widgets/unplug_timer_screen.dart';
import '../animations/fade_scale_switcher.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  static const routeName = '/';

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const destinations = <_Destination>[
      _Destination(
        icon: Icons.alarm_rounded,
        label: 'Alarms',
        child: AlarmDashboard(),
      ),
      _Destination(
        icon: Icons.auto_graph_rounded,
        label: 'Sleep debt',
        child: SleepDebtDashboard(),
      ),
      _Destination(
        icon: Icons.spa_rounded,
        label: 'Unplug',
        child: UnplugTimerScreen(),
      ),
    ];

    return Scaffold(
      body: FadeScaleSwitcher(
        child: destinations[_index].child,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;
}
