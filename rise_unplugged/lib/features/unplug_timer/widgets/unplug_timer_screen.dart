import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../alarms/models/alarm.dart';
import '../../alarms/models/alarm_mission.dart';
import '../../alarms/providers/alarm_schedule_provider.dart';
import '../models/unplug_timer.dart';
import '../providers/unplug_timer_provider.dart';
import 'wake_verification_dialog.dart';

class UnplugTimerScreen extends ConsumerWidget {
  const UnplugTimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(unplugTimerProvider);
    final notifier = ref.read(unplugTimerProvider.notifier);
    final mission = ref.watch(alarmScheduleProvider).maybeWhen(
          data: (alarms) => _activeMission(alarms),
          orElse: () => null,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unplug timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_suggest),
            onPressed: () async {
              final config = await _configure(context, state.config);
              if (!context.mounted) {
                return;
              }
              if (config != null) {
                notifier.configure(config);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.25),
                      Theme.of(
                        context,
                      ).colorScheme.secondary.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      _formatDuration(state.remaining ?? state.config.duration),
                      key: ValueKey(
                        state.remaining?.inSeconds ??
                            state.config.duration.inSeconds,
                      ),
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: state.isRunning
                  ? notifier.stop
                  : () async {
                      if (state.config.requireVerification) {
                        final verified = await showDialog<bool>(
                              context: context,
                              builder: (context) =>
                                  WakeVerificationDialog(mission: mission),
                            ) ??
                            false;
                        if (!context.mounted) {
                          return;
                        }
                        if (!verified) {
                          return;
                        }
                        notifier.verifyWake();
                      }
                      notifier.start();
                    },
              child: Text(
                state.isRunning ? 'Stop ritual' : 'Begin unplug ritual',
              ),
            ),
            const SizedBox(height: 16),
            if (state.config.blockDistractions)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Distraction blocking enabled. Try to keep your focus on the calming visual and breathing.',
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<UnplugTimerConfig?> _configure(
    BuildContext context,
    UnplugTimerConfig config,
  ) async {
    return showModalBottomSheet<UnplugTimerConfig>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        var temp = config;
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ritual settings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    value: temp.duration.inMinutes.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    label: '${temp.duration.inMinutes} minutes',
                    onChanged: (value) => setState(
                      () => temp = temp.copyWith(
                        duration: Duration(minutes: value.toInt()),
                      ),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    title: const Text('Wake verification'),
                    subtitle: const Text(
                      'Confirm you are awake with a quick breathing check',
                    ),
                    value: temp.requireVerification,
                    onChanged: (value) => setState(
                      () => temp = temp.copyWith(requireVerification: value),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    title: const Text('Block distractions'),
                    subtitle: const Text(
                      'Limit notifications while the ritual runs',
                    ),
                    value: temp.blockDistractions,
                    onChanged: (value) => setState(
                      () => temp = temp.copyWith(blockDistractions: value),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(temp),
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${duration.inHours}:$minutes:$seconds';
  }

  AlarmMission? _activeMission(List<Alarm> alarms) {
    final now = DateTime.now();
    final candidates = alarms
        .where((alarm) => alarm.enabled && alarm.mission != null)
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    if (candidates.isEmpty) {
      return null;
    }
    final upcoming = candidates.firstWhere(
      (alarm) => !alarm.scheduledTime.isBefore(now),
      orElse: () => candidates.first,
    );
    return upcoming.mission;
  }
}
