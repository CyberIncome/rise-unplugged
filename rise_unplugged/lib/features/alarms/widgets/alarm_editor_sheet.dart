import 'package:flutter/material.dart';

import '../models/alarm.dart';
import '../models/alarm_mission.dart';
import '../models/follow_up_alarm.dart';
import '../models/ringtone.dart';
import '../services/alarm_mission_catalog.dart';
import '../services/alarm_templates.dart';

class AlarmEditorSheet extends StatefulWidget {
  const AlarmEditorSheet({super.key, this.initialAlarm});

  final Alarm? initialAlarm;

  @override
  State<AlarmEditorSheet> createState() => _AlarmEditorSheetState();
}

class _AlarmEditorSheetState extends State<AlarmEditorSheet> {
  late TimeOfDay _time;
  late TextEditingController _labelController;
  late List<FollowUpAlarm> _followUps;
  Duration? _smartWindow;
  Ringtone _ringtone = const Ringtone.defaultTone();
  AlarmMission? _mission;
  AlarmTemplate? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAlarm;
    _time = initial != null
        ? TimeOfDay.fromDateTime(initial.scheduledTime)
        : TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 8)));
    _labelController = TextEditingController(
      text: initial?.label ?? 'Rise gently',
    );
    _followUps = List.from(initial?.followUps ?? const <FollowUpAlarm>[]);
    _smartWindow = initial?.smartWakeWindow;
    _ringtone = initial?.ringtone ?? const Ringtone.defaultTone();
    _mission = initial?.mission ?? AlarmMissionCatalog.defaultMission;
    _selectedTemplate = null;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            widget.initialAlarm == null ? 'Create alarm' : 'Edit alarm',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(labelText: 'Label'),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Suggested routine'),
            subtitle: Text(
              _selectedTemplate != null
                  ? _selectedTemplate!.name
                  : 'Browse curated combos to auto-fill missions, follow-ups, and tones.',
            ),
            trailing: const Icon(Icons.auto_awesome),
            onTap: () => _pickTemplate(context),
          ),
          if (_selectedTemplate != null) ...[
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedTemplate!.description,
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (_selectedTemplate!.tags.isNotEmpty ||
                        _selectedTemplate!.recommendedTime != null ||
                        _selectedTemplate!.smartWindow != null) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (_selectedTemplate!.recommendedTime != null)
                            Chip(
                              avatar: const Icon(Icons.schedule, size: 16),
                              label: Text(
                                localizations.formatTimeOfDay(
                                  _selectedTemplate!.recommendedTime!,
                                ),
                              ),
                            ),
                          if (_selectedTemplate!.smartWindow != null)
                            Chip(
                              avatar: const Icon(Icons.timelapse, size: 16),
                              label: Text(
                                '${_selectedTemplate!.smartWindow!.inMinutes} min window',
                              ),
                            ),
                          if (_selectedTemplate!.mission.difficulty.label.isNotEmpty)
                            Chip(
                              avatar: const Icon(Icons.bolt, size: 16),
                              label:
                                  Text(_selectedTemplate!.mission.difficulty.label),
                            ),
                          for (final tag in _selectedTemplate!.tags)
                            Chip(label: Text(tag)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _selectedTemplate = null),
                      child: const Text('Keep values, hide template info'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ] else
            const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Wake time'),
            subtitle: Text(
              localizations.formatTimeOfDay(_time),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final result = await showTimePicker(
                context: context,
                initialTime: _time,
              );
              if (result != null) {
                setState(() => _time = result);
              }
            },
          ),
          SwitchListTile.adaptive(
            title: const Text('Smart wake window'),
            subtitle: Text(
              _smartWindow != null
                  ? 'Within ${_smartWindow!.inMinutes} minutes of REM cycle'
                  : 'Off',
            ),
            value: _smartWindow != null,
            onChanged: (value) async {
              if (value) {
                final duration = await _pickDuration(
                  context,
                  _smartWindow ?? const Duration(minutes: 20),
                );
                if (duration != null) {
                  setState(() => _smartWindow = duration);
                }
              } else {
                setState(() => _smartWindow = null);
              }
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ringtone'),
            subtitle: Text(_ringtone.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final tone = await _pickRingtone(context, _ringtone);
              if (tone != null) {
                setState(() => _ringtone = tone);
              }
            },
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Wake mission'),
            subtitle: Text(
              _mission != null
                  ? '${_mission!.name} · ${_mission!.difficulty.label}'
                  : 'Optional task to guarantee you are truly awake',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final mission = await _pickMission(context, _mission);
              if (mission != null) {
                setState(() => _mission = mission);
              }
            },
          ),
          if (_mission != null) ...[
            const SizedBox(height: 8),
            Text(_mission!.description, style: theme.textTheme.bodySmall),
            if (_mission!.cues.isNotEmpty) ...[
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final cue in _mission!.cues)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Icon(Icons.check_circle_outline, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(cue)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(label: Text(_mission!.difficulty.label)),
                Chip(label: Text(_missionTypeLabel(_mission!))),
                Chip(label: Text(_missionTag(_mission!))),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _mission = null),
                child: const Text('Remove mission'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Follow-up nudges', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (var i = 0; i < _followUps.length; i++)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: Text('After ${_followUps[i].delay.inMinutes} minutes'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_followUps[i].message),
                    if ((_followUps[i].recommendation ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _followUps[i].recommendation!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                  ],
                ),
                onTap: () async {
                  final updated =
                      await _pickFollowUp(context, initial: _followUps[i]);
                  if (updated != null) {
                    setState(() => _followUps[i] = updated);
                  }
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _followUps.removeAt(i)),
                ),
              ),
            ),
          TextButton.icon(
            onPressed: () async {
              final result = await _pickFollowUp(context);
              if (result != null) {
                setState(() => _followUps.add(result));
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add follow-up'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              final now = DateTime.now();
              final scheduled = DateTime(
                now.year,
                now.month,
                now.day,
                _time.hour,
                _time.minute,
              );
              final alarm = (widget.initialAlarm ??
                      Alarm(
                        label: _labelController.text,
                        scheduledTime: scheduled,
                      ))
                  .copyWith(
                label: _labelController.text,
                scheduledTime: scheduled,
                followUps: _followUps,
                smartWakeWindow: _smartWindow,
                ringtone: _ringtone,
                mission: _mission,
                clearMission: _mission == null,
              );
              Navigator.of(context).pop(alarm);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTemplate(BuildContext context) async {
    final template = await showModalBottomSheet<AlarmTemplate>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final localizations = MaterialLocalizations.of(context);
        return ListView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          children: [
            Text(
              'Suggested routines',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final template in AlarmTemplateCatalog.featured)
              Card(
                child: ListTile(
                  title: Text(template.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 4),
                      Text(template.description),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (template.recommendedTime != null)
                            Chip(
                              avatar: const Icon(Icons.schedule, size: 16),
                              label: Text(
                                localizations.formatTimeOfDay(
                                  template.recommendedTime!,
                                ),
                              ),
                            ),
                          Chip(label: Text(template.mission.name)),
                          for (final tag in template.tags)
                            Chip(label: Text(tag)),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.check_circle_outline),
                  onTap: () => Navigator.of(context).pop(template),
                ),
              ),
          ],
        );
      },
    );
    if (!context.mounted) {
      return;
    }
    if (template != null) {
      setState(() {
        _applyTemplate(template);
      });
    }
  }

  void _applyTemplate(AlarmTemplate template) {
    _selectedTemplate = template;
    _labelController.text = template.recommendedLabel;
    if (template.recommendedTime != null) {
      _time = template.recommendedTime!;
    }
    _mission = template.mission;
    _followUps = template.followUps.map((e) => e).toList(growable: true);
    _smartWindow = template.smartWindow;
    if (template.ringtone != null) {
      _ringtone = template.ringtone!;
    }
  }

  Future<Duration?> _pickDuration(
    BuildContext context,
    Duration initial,
  ) async {
    Duration? selected = initial;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Smart window length',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Slider(
                value: (selected?.inMinutes ?? initial.inMinutes).toDouble(),
                min: 10,
                max: 60,
                divisions: 10,
                label: '${selected?.inMinutes ?? initial.inMinutes} minutes',
                onChanged: (value) =>
                    setState(() => selected = Duration(minutes: value.toInt())),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      },
    );
    return selected;
  }

  Future<Ringtone?> _pickRingtone(
    BuildContext context,
    Ringtone current,
  ) async {
    const options = <Ringtone>[
      Ringtone(
        assetPath: 'assets/ringtones/sunrise.mp3',
        name: 'Sunrise Drift',
      ),
      Ringtone(assetPath: 'assets/ringtones/forest.mp3', name: 'Forest Wake'),
      Ringtone(assetPath: 'assets/ringtones/tide.mp3', name: 'Ocean Tide'),
    ];
    final selection = await showModalBottomSheet<Ringtone>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListView(
          children: [
            for (final option in options)
              ListTile(
                title: Text(option.name),
                subtitle: Text(option.assetPath),
                trailing: option == current ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        );
      },
    );
    if (!context.mounted) {
      return null;
    }
    return selection;
  }

  Future<FollowUpAlarm?> _pickFollowUp(
    BuildContext context, {
    FollowUpAlarm? initial,
  }) async {
    Duration delay = initial?.delay ?? const Duration(minutes: 10);
    final messageController = TextEditingController(
      text: initial?.message ?? 'Time to stretch and shine!',
    );
    final recommendationController = TextEditingController(
      text: initial?.recommendation ?? '',
    );
    FollowUpAlarm? result;
    const suggestions = [
      FollowUpAlarm(
        delay: Duration(minutes: 5),
        message: 'Hydrate and open the blinds.',
        recommendation: 'Drink water and welcome sunlight.',
      ),
      FollowUpAlarm(
        delay: Duration(minutes: 12),
        message: 'Stretch for two minutes.',
        recommendation: 'Focus on neck and shoulders.',
      ),
      FollowUpAlarm(
        delay: Duration(minutes: 20),
        message: 'Review today\'s top priority.',
        recommendation: 'Open your planner or notes.',
      ),
    ];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
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
                    initial == null ? 'Follow-up nudge' : 'Edit follow-up',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    value: delay.inMinutes.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    label: '${delay.inMinutes} minutes',
                    onChanged: (value) => modalSetState(
                      () => delay = Duration(minutes: value.toInt()),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final suggestion in suggestions)
                          ActionChip(
                            avatar: const Icon(Icons.bolt, size: 16),
                            label: Text(
                              '${suggestion.delay.inMinutes}m · ${suggestion.message}',
                            ),
                            onPressed: () {
                              modalSetState(
                                () => delay = suggestion.delay,
                              );
                              messageController.text = suggestion.message;
                              recommendationController.text =
                                  suggestion.recommendation ?? '';
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: messageController,
                    decoration: const InputDecoration(labelText: 'Message'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: recommendationController,
                    decoration: const InputDecoration(
                      labelText: 'Recommendation (optional)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      result = FollowUpAlarm(
                        delay: delay,
                        message: messageController.text,
                        recommendation: recommendationController.text.isEmpty
                            ? null
                            : recommendationController.text,
                      );
                      Navigator.of(context).pop();
                    },
                    child: Text(initial == null ? 'Add' : 'Save'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    messageController.dispose();
    recommendationController.dispose();
    return result;
  }

  Future<AlarmMission?> _pickMission(
    BuildContext context,
    AlarmMission? current,
  ) async {
    var selectedDifficulty =
        current?.difficulty ?? AlarmMissionCatalog.defaultMission.difficulty;
    var selectedType = current?.type ?? AlarmMissionCatalog.defaultMission.type;
    return showModalBottomSheet<AlarmMission>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final preview = AlarmMissionCatalog.buildMission(
              type: selectedType,
              difficulty: selectedDifficulty,
            );
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose your wake mission',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<AlarmMissionDifficulty>(
                    segments: [
                      for (final difficulty in AlarmMissionDifficulty.values)
                        ButtonSegment(
                          value: difficulty,
                          label: Text(difficulty.label),
                        ),
                    ],
                    selected: {selectedDifficulty},
                    onSelectionChanged: (value) =>
                        setModalState(() => selectedDifficulty = value.first),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 260,
                    child: ListView(
                      children: [
                        for (final type in AlarmMissionType.values)
                          Builder(
                            builder: (context) {
                              final mission = AlarmMissionCatalog.buildMission(
                                type: type,
                                difficulty: selectedDifficulty,
                              );
                              final isSelected = type == selectedType;
                              return Card(
                                color: isSelected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer
                                    : null,
                                child: ListTile(
                                  title: Text(mission.name),
                                  subtitle: Text(mission.description),
                                  trailing: isSelected
                                      ? Icon(
                                          Icons.check_circle,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSecondaryContainer,
                                        )
                                      : null,
                                  onTap: () => setModalState(
                                    () => selectedType = type,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(preview),
                    child: const Text('Save mission'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _missionTypeLabel(AlarmMission mission) {
    switch (mission.type) {
      case AlarmMissionType.breathwork:
        return 'Breathwork';
      case AlarmMissionType.mathQuiz:
        return 'Mental math';
      case AlarmMissionType.focusTap:
        return 'Focus taps';
      case AlarmMissionType.affirmation:
        return 'Affirmation';
      case AlarmMissionType.barcodeScan:
        return 'Barcode scan';
      case AlarmMissionType.photoProof:
        return 'Photo proof';
      case AlarmMissionType.stepCounter:
        return 'Steps challenge';
      case AlarmMissionType.memoryGrid:
        return 'Memory grid';
      case AlarmMissionType.breathAndAffirm:
        return 'Breath + affirm';
    }
  }

  String _missionTag(AlarmMission mission) {
    switch (mission.type) {
      case AlarmMissionType.breathwork:
        return '${mission.target} breaths';
      case AlarmMissionType.mathQuiz:
        return mission.difficulty == AlarmMissionDifficulty.intense
            ? 'Advanced math'
            : 'Math challenge';
      case AlarmMissionType.focusTap:
        return '${mission.target} taps';
      case AlarmMissionType.affirmation:
        return 'Speak your mantra';
      case AlarmMissionType.barcodeScan:
        return 'Scan your checkpoint';
      case AlarmMissionType.photoProof:
        return 'Snap progress';
      case AlarmMissionType.stepCounter:
        return '${mission.target} steps';
      case AlarmMissionType.memoryGrid:
        return '${mission.target} patterns';
      case AlarmMissionType.breathAndAffirm:
        return '${mission.target} breaths + affirmation';
    }
  }
}
