import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../services/health/health_integration_service.dart';
import '../../../shared/utils/feature_flags.dart';
import '../models/sleep_session.dart';
import '../providers/sleep_debt_provider.dart';

enum _ImportAction { appleHealth, googleFit }

class SleepDebtDashboard extends ConsumerWidget {
  const SleepDebtDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sleepDebtProvider);
    final flags = ref.watch(featureFlagsProvider);
    final entries = state.weeklyDebt.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final totalDebtMinutes = entries.fold<int>(
      0,
      (previousValue, element) => previousValue + element.value.inMinutes,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep debt'),
        actions: [
          PopupMenuButton<_ImportAction>(
            tooltip: 'Import sleep data',
            icon: const Icon(Icons.cloud_sync_outlined),
            onSelected: (action) => _handleImport(context, ref, action),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _ImportAction.appleHealth,
                child: Text('Import from Apple Health'),
              ),
              PopupMenuItem(
                value: _ImportAction.googleFit,
                child: Text('Import from Google Fit'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showTooltip(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addSession(context, ref),
        icon: const Icon(Icons.bedtime),
        label: const Text('Log sleep'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _WeeklyDebtCard(entries: entries, goal: state.goalPerNight),
          const SizedBox(height: 16),
          _InsightsCard(
            flags: flags,
            entries: entries,
            goal: state.goalPerNight,
            totalDebtMinutes: totalDebtMinutes,
            tooltipVisible: !state.tooltipsSeen.contains('sleep_debt_info'),
          ),
          const SizedBox(height: 16),
          _SessionHistoryCard(sessions: state.sessions),
        ],
      ),
    );
  }

  Future<void> _handleImport(
    BuildContext context,
    WidgetRef ref,
    _ImportAction action,
  ) async {
    final notifier = ref.read(sleepDebtProvider.notifier);
    final result = await notifier.importFromHealth(
      switch (action) {
        _ImportAction.appleHealth => const AppleHealthIntegrationService(),
        _ImportAction.googleFit => const GoogleFitIntegrationService(),
      },
    );

    if (!context.mounted) return;

    final message = switch (result) {
      SleepImportResult.unavailable =>
        'The selected health platform is not available on this device.',
      SleepImportResult.permissionDenied =>
        'Permissions were not granted. Please enable access in settings.',
      SleepImportResult.noData =>
        'No recent sleep sessions were found to import.',
      SleepImportResult.imported => 'Sleep history imported successfully!',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showTooltip(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sleep debt basics'),
          content: Text(
            'Sleep debt represents the difference between the rest you aim for each night and '
            'what you actually get. Use the chart to spot patterns and recover gradually.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
    ref.read(sleepDebtProvider.notifier).dismissTooltip('sleep_debt_info');
  }

  Future<void> _addSession(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    var start = now.subtract(const Duration(hours: 7));
    var end = now;
    var source = SleepSessionSource.manual;

    final session = await showModalBottomSheet<SleepSession>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickStart() async {
              final result = await _pickDateTime(context, start);
              if (result != null) {
                setState(() => start = result);
                if (!end.isAfter(start)) {
                  setState(() => end = start.add(const Duration(hours: 1)));
                }
              }
            }

            Future<void> pickEnd() async {
              final result = await _pickDateTime(context, end);
              if (result != null) {
                setState(() => end = result.isAfter(start)
                    ? result
                    : start.add(const Duration(hours: 1)));
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Log sleep session',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start'),
                    subtitle: Text(DateFormat.yMMMd().add_jm().format(start)),
                    onTap: pickStart,
                    trailing: const Icon(Icons.edit_calendar),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('End'),
                    subtitle: Text(DateFormat.yMMMd().add_jm().format(end)),
                    onTap: pickEnd,
                    trailing: const Icon(Icons.edit_calendar),
                  ),
                  DropdownButtonFormField<SleepSessionSource>(
                    initialValue: source,
                    decoration: const InputDecoration(labelText: 'Source'),
                    items: const [
                      DropdownMenuItem(
                        value: SleepSessionSource.manual,
                        child: Text('Logged manually'),
                      ),
                      DropdownMenuItem(
                        value: SleepSessionSource.appleHealth,
                        child: Text('Apple Health'),
                      ),
                      DropdownMenuItem(
                        value: SleepSessionSource.googleFit,
                        child: Text('Google Fit'),
                      ),
                    ],
                    onChanged: (value) => setState(
                        () => source = value ?? SleepSessionSource.manual),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        SleepSession(start: start, end: end, source: source),
                      );
                    },
                    child: const Text('Save sleep session'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (session == null) {
      return;
    }

    await ref.read(sleepDebtProvider.notifier).addSession(session);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sleep session saved.')),
    );
  }

  Future<DateTime?> _pickDateTime(
      BuildContext context, DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null) {
      return null;
    }
    if (!context.mounted) {
      return null;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) {
      return null;
    }
    if (!context.mounted) {
      return null;
    }
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}

class _WeeklyDebtCard extends StatelessWidget {
  const _WeeklyDebtCard({
    required this.entries,
    required this.goal,
  });

  final List<MapEntry<DateTime, Duration>> entries;
  final Duration goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entries.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Weekly debt', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              const Text('Log a few nights to generate your first insights.'),
            ],
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly debt', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  alignment: BarChartAlignment.spaceAround,
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (value, _) =>
                            Text('${value.toInt()}m'),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final index = value.toInt();
                          if (index < 0 || index >= entries.length) {
                            return const SizedBox.shrink();
                          }
                          final date = entries[index].key;
                          return Text(DateFormat.Md().format(date));
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < entries.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: entries[i].value.inMinutes.toDouble(),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(12)),
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Goal: ${goal.inHours} hrs nightly'),
          ],
        ),
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({
    required this.flags,
    required this.entries,
    required this.goal,
    required this.totalDebtMinutes,
    required this.tooltipVisible,
  });

  final FeatureFlags flags;
  final List<MapEntry<DateTime, Duration>> entries;
  final Duration goal;
  final int totalDebtMinutes;
  final bool tooltipVisible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = _insightMessage(entries, goal, flags, totalDebtMinutes);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Insights', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            AnimatedOpacity(
              opacity: tooltipVisible ? 1 : 0.7,
              duration: const Duration(milliseconds: 300),
              child: Text(message),
            ),
          ],
        ),
      ),
    );
  }

  String _insightMessage(
    List<MapEntry<DateTime, Duration>> entries,
    Duration goal,
    FeatureFlags flags,
    int totalDebtMinutes,
  ) {
    if (entries.isEmpty) {
      return 'Log your sleep to see weekly debt trends and recommendations.';
    }
    if (totalDebtMinutes <= goal.inMinutes) {
      return 'Beautiful work! You are within a single night of your goal.';
    }
    if (flags.enableAiInsights) {
      return 'AI insights recommend an earlier wind-down based on your recent wake patterns.';
    }
    if (flags.enableStreaks) {
      return 'Keep your streak alive by targeting a 15-minute earlier bedtime tonight.';
    }
    if (flags.enableExports) {
      return 'Export your data to review longer-term trends with your sleep coach.';
    }
    return 'Consider adding a 20-minute nap or heading to bed 30 minutes earlier tonight.';
  }
}

class _SessionHistoryCard extends StatelessWidget {
  const _SessionHistoryCard({required this.sessions});

  final List<SleepSession> sessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recentSessions = sessions.reversed.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent sessions', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (recentSessions.isEmpty)
              const Text(
                  'No sessions logged yet. Start by adding last night\'s sleep.'),
            for (final session in recentSessions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.nightlight_round,
                  color: theme.colorScheme.primary,
                ),
                title: Text(DateFormat.yMMMd().add_jm().format(session.start)),
                subtitle: Text(
                  '${_formatDuration(session.duration)} • ${_sourceLabel(session.source)}',
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) {
      return '$minutes min';
    }
    return minutes == 0 ? '$hours h' : '$hours h $minutes min';
  }

  String _sourceLabel(SleepSessionSource source) {
    return switch (source) {
      SleepSessionSource.manual => 'Manual log',
      SleepSessionSource.appleHealth => 'Apple Health',
      SleepSessionSource.googleFit => 'Google Fit',
    };
  }
}
