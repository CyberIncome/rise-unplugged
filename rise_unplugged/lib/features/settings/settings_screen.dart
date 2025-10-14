import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/utils/feature_flags.dart';
import '../sleep_debt/providers/sleep_debt_provider.dart';
import '../unplug_timer/providers/unplug_timer_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);
    final flags = ref.watch(featureFlagsProvider);
    final sleepDebtState = ref.watch(sleepDebtProvider);
    final unplugState = ref.watch(unplugTimerProvider);

    final preference = _currentThemePreference(theme.mode);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemePreference>(
              segments: const [
                ButtonSegment(
                  value: ThemePreference.system,
                  label: Text('System'),
                  icon: Icon(Icons.auto_mode),
                ),
                ButtonSegment(
                  value: ThemePreference.light,
                  label: Text('Light'),
                  icon: Icon(Icons.wb_sunny_outlined),
                ),
                ButtonSegment(
                  value: ThemePreference.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.nightlight_round),
                ),
              ],
              selected: {preference},
              onSelectionChanged: (selection) {
                final value = selection.first;
                ref.read(appThemeProvider.notifier).updatePreference(value);
              },
            ),
          ),
          const _SectionHeader(title: 'Sleep debt'),
          ListTile(
            title: const Text('Goal per night'),
            subtitle: Text(
                '${theme.mode == ThemeMode.dark ? 'Rest deeply' : 'Rest well'}: '
                '${sleepDebtState.goalPerNight.inHours} hours'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final goal =
                  await _selectGoal(context, sleepDebtState.goalPerNight);
              if (!context.mounted) {
                return;
              }
              if (goal != null) {
                await ref
                    .read(sleepDebtProvider.notifier)
                    .setGoalPerNight(goal);
              }
            },
          ),
          const _SectionHeader(title: 'Feature previews'),
          SwitchListTile.adaptive(
            title: const Text('AI insights'),
            value: flags.enableAiInsights,
            onChanged: (value) =>
                ref.read(featureFlagsProvider.notifier).setAiInsights(value),
          ),
          SwitchListTile.adaptive(
            title: const Text('Streak celebrations'),
            value: flags.enableStreaks,
            onChanged: (value) =>
                ref.read(featureFlagsProvider.notifier).setStreaks(value),
          ),
          SwitchListTile.adaptive(
            title: const Text('Exports & reports'),
            value: flags.enableExports,
            onChanged: (value) =>
                ref.read(featureFlagsProvider.notifier).setExports(value),
          ),
          SwitchListTile.adaptive(
            title: const Text('Aesthetic refresh'),
            value: flags.isAestheticRefreshEnabled,
            onChanged: (value) => ref
                .read(featureFlagsProvider.notifier)
                .setAestheticRefresh(value),
          ),
          const _SectionHeader(title: 'Unplug timer'),
          ListTile(
            title: const Text('Default duration'),
            subtitle: Text('${unplugState.config.duration.inMinutes} minutes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final updated =
                  await _selectDuration(context, unplugState.config.duration);
              if (!context.mounted) {
                return;
              }
              if (updated != null) {
                ref
                    .read(unplugTimerProvider.notifier)
                    .configure(unplugState.config.copyWith(duration: updated));
              }
            },
          ),
        ],
      ),
    );
  }

  ThemePreference _currentThemePreference(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return ThemePreference.dark;
      case ThemeMode.light:
        return ThemePreference.light;
      case ThemeMode.system:
        return ThemePreference.system;
    }
  }

  Future<Duration?> _selectGoal(BuildContext context, Duration current) async {
    return showModalBottomSheet<Duration>(
      context: context,
      builder: (context) {
        var goal = current;
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Nightly goal',
                      style: Theme.of(context).textTheme.titleMedium),
                  Slider(
                    value: goal.inHours.toDouble(),
                    min: 6,
                    max: 10,
                    divisions: 8,
                    label: '${goal.inHours} hours',
                    onChanged: (value) =>
                        setState(() => goal = Duration(hours: value.round())),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(goal),
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Duration?> _selectDuration(
      BuildContext context, Duration current) async {
    return showDialog<Duration>(
      context: context,
      builder: (context) {
        var minutes = current.inMinutes.toDouble();
        return AlertDialog(
          title: const Text('Default duration'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Slider(
                value: minutes,
                min: 5,
                max: 60,
                divisions: 11,
                label: '${minutes.toInt()} minutes',
                onChanged: (value) => setState(() => minutes = value),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(Duration(minutes: minutes.round())),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
