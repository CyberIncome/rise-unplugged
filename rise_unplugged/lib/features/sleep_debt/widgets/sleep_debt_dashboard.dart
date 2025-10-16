import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../services/health/health_integration_service.dart';
import '../../../shared/utils/feature_flags.dart';
import '../models/sleep_persona.dart';
import '../models/sleep_session.dart';
import '../providers/sleep_debt_provider.dart';
import '../services/sleep_debt_export_service.dart';

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
            persona: state.persona,
            sessions: state.sessions,
            weeklyDigestEnabled: state.weeklyDigestEnabled,
            onDigestToggled: (value) =>
                _toggleWeeklyDigest(context, ref, value),
            onExport: () => _exportSessions(context, state.sessions),
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

  Future<void> _toggleWeeklyDigest(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    await ref
        .read(sleepDebtProvider.notifier)
        .setWeeklyDigestEnabled(enabled);
    if (!context.mounted) {
      return;
    }
    final message = enabled
        ? 'Weekly digest enabled. Expect a Sunday morning summary.'
        : 'Weekly digest disabled.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _exportSessions(
    BuildContext context,
    List<SleepSession> sessions,
  ) async {
    if (sessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Log at least one session to export a summary.'),
        ),
      );
      return;
    }

    try {
      await const SleepDebtExportService().shareSessions(sessions);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sleep summary ready to share!')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to share summary: $error')),
      );
    }
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
    required this.persona,
    required this.sessions,
    required this.weeklyDigestEnabled,
    required this.onDigestToggled,
    required this.onExport,
  });

  final FeatureFlags flags;
  final List<MapEntry<DateTime, Duration>> entries;
  final Duration goal;
  final int totalDebtMinutes;
  final bool tooltipVisible;
  final SleepPersona? persona;
  final List<SleepSession> sessions;
  final bool weeklyDigestEnabled;
  final ValueChanged<bool> onDigestToggled;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insights = _buildInsights(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Insights', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            AnimatedOpacity(
              opacity: tooltipVisible ? 1 : 0.82,
              duration: const Duration(milliseconds: 300),
              child: Column(
                children: [
                  for (var i = 0; i < insights.length; i++) ...[
                    _InsightTile(insight: insights[i]),
                    if (i != insights.length - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            if (flags.enableExports) ...[
              const Divider(height: 32),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: weeklyDigestEnabled,
                onChanged: onDigestToggled,
                title: const Text('Auto-share weekly digest'),
                subtitle: const Text(
                  'Receive a Sunday morning summary with debt trends and wins.',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: sessions.isEmpty ? null : onExport,
                      icon: const Icon(Icons.ios_share_outlined),
                      label: const Text('Export latest report'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<_Insight> _buildInsights(BuildContext context) {
    if (entries.isEmpty) {
      return const [
        _Insight(
          icon: Icons.explore_outlined,
          title: 'Start logging',
          message:
              'Capture at least three nights of sleep to unlock personalised coaching.',
        ),
      ];
    }

    final nightsTracked = entries.length;
    final restfulNights =
        entries.where((entry) => entry.value.inMinutes <= 15).length;
    final locale = MaterialLocalizations.of(context);
    final baseLightsOut = persona?.chronotype.idealLightsOut ??
        const TimeOfDay(hour: 22, minute: 30);
    final recommendedShift = _recommendedAdjustment();
    final adjustedLightsOut = _shift(baseLightsOut, minutes: -recommendedShift);
    final lightsOutLabel = locale.formatTimeOfDay(adjustedLightsOut);
    final debtLabel = _formatDebt();
    final insights = <_Insight>[];

    if (totalDebtMinutes <= goal.inMinutes) {
      insights.add(_Insight(
        icon: Icons.celebration_outlined,
        title: 'Sleep debt recovered',
        message:
            'Beautiful work! Keep lights out near $lightsOutLabel to protect your gains.',
      ));
    } else {
      final prefix = flags.enableAiInsights ? 'AI cue • ' : '';
      insights.add(_Insight(
        icon: Icons.auto_awesome_outlined,
        title: '${prefix}Tonight\'s recovery target',
        message:
            'Aim for lights out around $lightsOutLabel — about $recommendedShift minutes earlier — to chip away at $debtLabel of sleep debt.',
      ));
    }

    if (persona != null) {
      insights
        ..add(_Insight(
          icon: Icons.bedtime_outlined,
          title: '${persona!.chronotype.label} rhythm',
          message:
              '${persona!.chronotype.summary} Use the $lightsOutLabel lights-out cue to align with your natural rhythm.',
        ))
        ..add(_Insight(
          icon: Icons.alarm_on_outlined,
          title: 'Wake backup plan',
          message: persona!.challenge.insight,
        ))
        ..add(_Insight(
          icon: Icons.self_improvement_outlined,
          title: 'Morning ritual focus',
          message: persona!.morningFocus.ritualSuggestion,
        ));
    } else {
      insights.add(const _Insight(
        icon: Icons.timeline_outlined,
        title: 'Lock in a wind-down',
        message:
            'Pick a consistent wind-down 45 minutes before bed to help shrink your sleep debt.',
      ));
    }

    insights.add(_Insight(
      icon: Icons.emoji_events_outlined,
      title: 'Streak momentum',
      message: restfulNights > 0
          ? '$restfulNights of $nightsTracked nights met your goal. Keep the streak alive tonight.'
          : 'No goal nights logged yet. Schedule a recovery evening within the next three days.',
    ));

    return insights;
  }

  int _recommendedAdjustment() {
    if (entries.isEmpty || totalDebtMinutes <= 0) {
      return 0;
    }
    final nightlyDebt = totalDebtMinutes / entries.length;
    final clamped = nightlyDebt.clamp(10, 90);
    final rounded = (clamped / 5).ceil() * 5;
    return rounded.toInt();
  }

  String _formatDebt() {
    if (totalDebtMinutes <= 0) {
      return '0m';
    }
    final hours = totalDebtMinutes ~/ 60;
    final minutes = totalDebtMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    }
    if (hours > 0) {
      return '${hours}h';
    }
    return '${minutes}m';
  }

  TimeOfDay _shift(TimeOfDay time, {int minutes = 0}) {
    final totalMinutes = time.hour * 60 + time.minute + minutes;
    final normalized = (totalMinutes % (24 * 60) + (24 * 60)) % (24 * 60);
    return TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60);
  }
}

class _Insight {
  const _Insight({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.insight});

  final _Insight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(insight.icon, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                insight.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                insight.message,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
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
