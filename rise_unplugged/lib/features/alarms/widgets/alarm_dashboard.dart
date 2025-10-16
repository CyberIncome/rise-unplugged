import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/alarm.dart';
import '../models/alarm_mission.dart';
import '../providers/alarm_schedule_provider.dart';
import 'alarm_editor_sheet.dart';
import '../../settings/settings_screen.dart';
import '../../sleep_debt/providers/sleep_debt_provider.dart';
import '../services/rem_cycle_service.dart';

class AlarmDashboard extends ConsumerWidget {
  const AlarmDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarms = ref.watch(alarmScheduleProvider);
    final sleepDebt = ref.watch(sleepDebtProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart alarms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(SettingsScreen.routeName),
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (_) => const _RemTipsSheet(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        label: const Text('Add alarm'),
        icon: const Icon(Icons.add_alarm),
      ),
      body: alarms.when(
        data: (data) {
          if (data.isEmpty) {
            return _EmptyAlarmsState(
              onCreate: () {
                _openEditor(context, ref);
              },
            );
          }
          final insight = _computeInsight(data, sleepDebt);
          return ListView(
            padding: const EdgeInsets.only(bottom: 96, top: 8),
            children: [
              if (insight != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _RemInsightCard(
                    insight: insight,
                    onApplySmartWindow: insight.smartWindow != null
                        ? () => ref
                            .read(alarmScheduleProvider.notifier)
                            .applyRemSuggestion(
                              insight.alarm,
                              insight.recommendedBedtime,
                            )
                        : null,
                  ),
                ),
              if (insight != null) const SizedBox(height: 12),
              for (final alarm in data)
                _AlarmTile(
                  alarm: alarm,
                  onEdit: (updated) async {
                    await ref
                        .read(alarmScheduleProvider.notifier)
                        .updateAlarm(updated);
                  },
                ),
            ],
          );
        },
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    Alarm? alarm,
  }) async {
    final result = await showModalBottomSheet<Alarm>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => AlarmEditorSheet(initialAlarm: alarm),
    );
    if (!context.mounted) return;
    if (result != null) {
      if (alarm == null) {
        await ref.read(alarmScheduleProvider.notifier).addAlarm(
              label: result.label,
              time: TimeOfDay.fromDateTime(result.scheduledTime),
              followUps: result.followUps,
              smartWakeWindow: result.smartWakeWindow,
              ringtone: result.ringtone,
              mission: result.mission,
            );
      } else {
        await ref.read(alarmScheduleProvider.notifier).updateAlarm(result);
      }
    }
  }
}

class _AlarmTile extends ConsumerWidget {
  const _AlarmTile({required this.alarm, required this.onEdit});

  final Alarm alarm;
  final ValueChanged<Alarm> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(alarm.scheduledTime),
      alwaysUse24HourFormat: false,
    );
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Switch(
          value: alarm.enabled,
          onChanged: (value) => ref
              .read(alarmScheduleProvider.notifier)
              .toggleAlarm(alarm, value),
        ),
        title: Text(
          time,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(alarm.label, style: theme.textTheme.bodyMedium),
            if (alarm.mission != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Chip(label: Text(alarm.mission!.name)),
                    Chip(label: Text(alarm.mission!.difficulty.label)),
                  ],
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () async {
            final selection = await showMenu<_AlarmAction>(
              context: context,
              position: const RelativeRect.fromLTRB(1, 80, 0, 0),
              items: const [
                PopupMenuItem(value: _AlarmAction.edit, child: Text('Edit')),
                PopupMenuItem(
                  value: _AlarmAction.rem,
                  child: Text('Add REM suggestion'),
                ),
                PopupMenuItem(
                  value: _AlarmAction.delete,
                  child: Text('Delete'),
                ),
              ],
            );
            if (!context.mounted) {
              return;
            }
            switch (selection) {
              case _AlarmAction.edit:
                final updated = await showModalBottomSheet<Alarm>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => AlarmEditorSheet(initialAlarm: alarm),
                );
                if (!context.mounted) {
                  return;
                }
                if (updated != null) {
                  onEdit(updated);
                }
                break;
              case _AlarmAction.rem:
                final bedtime = DateTime.now().subtract(
                  const Duration(hours: 8),
                );
                await ref
                    .read(alarmScheduleProvider.notifier)
                    .applyRemSuggestion(alarm, bedtime);
                break;
              case _AlarmAction.delete:
                await ref
                    .read(alarmScheduleProvider.notifier)
                    .removeAlarm(alarm);
                break;
              case null:
                break;
            }
          },
        ),
      ),
    );
  }
}

enum _AlarmAction { edit, rem, delete }

class _AlarmInsight {
  const _AlarmInsight({
    required this.alarm,
    required this.recommendedBedtime,
    required this.goalPerNight,
    required this.smartWindow,
    required this.cycleAnchors,
    required this.todaysDebt,
  });

  final Alarm alarm;
  final DateTime recommendedBedtime;
  final Duration goalPerNight;
  final Duration? smartWindow;
  final List<DateTime> cycleAnchors;
  final Duration todaysDebt;
}

_AlarmInsight? _computeInsight(
  List<Alarm> alarms,
  SleepDebtState sleepDebt,
) {
  final enabled = alarms.where((alarm) => alarm.enabled).toList();
  if (enabled.isEmpty) {
    return null;
  }
  enabled.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  final upcoming = enabled.first;
  final goal = sleepDebt.goalPerNight;
  final recommendedBedtime = upcoming.scheduledTime.subtract(goal);
  final remService = const RemCycleService();
  final anchors = remService
      .recommendedWakeTimes(targetWake: upcoming.scheduledTime, cycles: 4);
  final displayedAnchors = anchors.reversed.take(3).toList().reversed.toList();
  final smartWindow =
      remService.bestSmartWindow(recommendedBedtime, upcoming.scheduledTime);
  final today = DateTime.now();
  final todayKey = DateTime(today.year, today.month, today.day);
  final todaysDebt = sleepDebt.weeklyDebt[todayKey] ?? Duration.zero;
  return _AlarmInsight(
    alarm: upcoming,
    recommendedBedtime: recommendedBedtime,
    goalPerNight: goal,
    smartWindow: smartWindow,
    cycleAnchors: displayedAnchors,
    todaysDebt: todaysDebt,
  );
}

class _RemInsightCard extends StatelessWidget {
  const _RemInsightCard({
    required this.insight,
    this.onApplySmartWindow,
  });

  final _AlarmInsight insight;
  final VoidCallback? onApplySmartWindow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final bedtimeLabel = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(insight.recommendedBedtime),
    );
    final wakeLabel = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(insight.alarm.scheduledTime),
    );
    final cycleLabels = insight.cycleAnchors
        .map((anchor) => localizations.formatTimeOfDay(
              TimeOfDay.fromDateTime(anchor),
            ))
        .toList();
    final alarmLabel = insight.alarm.label.isEmpty
        ? 'your alarm'
        : '"${insight.alarm.label}"';
    final debtText = insight.todaysDebt > Duration.zero
        ? 'Sleep debt today: ${_formatDuration(insight.todaysDebt)} to recover.'
        : 'You are on track with your sleep goal today.';
    final smartWindowText = insight.smartWindow != null
        ? 'Suggested smart window: ${insight.smartWindow!.inMinutes} minutes.'
        : 'Log at least three full cycles tonight to unlock a smart window recommendation.';

    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tonight's wind-down plan",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aim to wind down by $bedtimeLabel for '
              '${_formatDuration(insight.goalPerNight)} of rest before '
              '$alarmLabel rings at $wakeLabel.',
            ),
            const SizedBox(height: 8),
            Text(debtText),
            const SizedBox(height: 12),
            if (cycleLabels.isNotEmpty) ...[
              Text('Cycle-friendly anchors'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final label in cycleLabels)
                    Chip(
                      avatar: const Icon(Icons.nightlight_round, size: 16),
                      label: Text(label),
                    ),
                  if (insight.smartWindow != null)
                    Chip(
                      avatar: const Icon(Icons.timelapse, size: 16),
                      label:
                          Text('${insight.smartWindow!.inMinutes} min window'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Text(smartWindowText),
            if (insight.smartWindow != null && onApplySmartWindow != null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onApplySmartWindow,
                icon: const Icon(Icons.bedtime),
                label: const Text('Apply smart window'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0 && minutes > 0) {
    return '${hours}h ${minutes}m';
  }
  if (hours > 0) {
    return '${hours}h';
  }
  return '${minutes}m';
}

class _EmptyAlarmsState extends StatelessWidget {
  const _EmptyAlarmsState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.alarm_add, size: 64),
            const SizedBox(height: 16),
            Text(
              'Schedule your first alarm',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a smart wake window to gently nudge you into the day with custom follow-ups.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_alarm),
              label: const Text('Add alarm'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemTipsSheet extends StatelessWidget {
  const _RemTipsSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REM-friendly wake windows', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          const Text(
            'Aim to wake at the end of a sleep cycle. Rise Unplugged recommends gentle windows '
            'and can schedule follow-up nudges that respect your natural rhythm.',
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
