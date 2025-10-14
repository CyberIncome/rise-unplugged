import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/alarm.dart';
import '../models/alarm_mission.dart';
import '../providers/alarm_schedule_provider.dart';
import 'alarm_editor_sheet.dart';
import '../../settings/settings_screen.dart';

class AlarmDashboard extends ConsumerWidget {
  const AlarmDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarms = ref.watch(alarmScheduleProvider);

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
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final alarm = data[index];
              return _AlarmTile(
                alarm: alarm,
                onEdit: (updated) async {
                  await ref
                      .read(alarmScheduleProvider.notifier)
                      .updateAlarm(updated);
                },
              );
            },
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
