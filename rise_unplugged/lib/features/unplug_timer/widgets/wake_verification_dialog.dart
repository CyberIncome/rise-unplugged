import 'dart:math';

import 'package:flutter/material.dart';

import '../../alarms/models/alarm_mission.dart';
import '../../alarms/services/alarm_mission_catalog.dart';

class WakeVerificationDialog extends StatefulWidget {
  const WakeVerificationDialog({super.key, this.mission});

  final AlarmMission? mission;

  @override
  State<WakeVerificationDialog> createState() => _WakeVerificationDialogState();
}

class _WakeVerificationDialogState extends State<WakeVerificationDialog> {
  late final AlarmMission _mission;
  int _breathsCompleted = 0;
  late final int _mathLeft;
  late final int _mathRight;
  late final String _mathOperator;
  late final int _mathAnswer;
  final TextEditingController _mathController = TextEditingController();
  late final List<int> _tapButtons;
  int _nextTap = 1;
  String? _tapError;

  @override
  void initState() {
    super.initState();
    _mission = widget.mission ?? AlarmMissionCatalog.defaultMission;
    final random = Random();
    switch (_mission.type) {
      case AlarmMissionType.mathQuiz:
        switch (_mission.difficulty) {
          case AlarmMissionDifficulty.gentle:
            _mathOperator = '+';
            _mathLeft = 10 + random.nextInt(20);
            _mathRight = 5 + random.nextInt(15);
            _mathAnswer = _mathLeft + _mathRight;
            break;
          case AlarmMissionDifficulty.focused:
            final subtract = random.nextBool();
            if (subtract) {
              _mathOperator = '-';
              _mathLeft = 25 + random.nextInt(25);
              _mathRight = 5 + random.nextInt(20);
              _mathAnswer = _mathLeft - _mathRight;
            } else {
              _mathOperator = '+';
              _mathLeft = 30 + random.nextInt(40);
              _mathRight = 15 + random.nextInt(25);
              _mathAnswer = _mathLeft + _mathRight;
            }
            break;
          case AlarmMissionDifficulty.intense:
            final multiply = random.nextBool();
            if (multiply) {
              _mathOperator = '×';
              _mathLeft = 4 + random.nextInt(8);
              _mathRight = 3 + random.nextInt(7);
              _mathAnswer = _mathLeft * _mathRight;
            } else {
              _mathOperator = '÷';
              _mathRight = 2 + random.nextInt(8);
              _mathAnswer = 3 + random.nextInt(7);
              _mathLeft = _mathRight * _mathAnswer;
            }
            break;
        }
        _tapButtons = const <int>[];
        break;
      case AlarmMissionType.focusTap:
        final values = List<int>.generate(
          _mission.target,
          (index) => index + 1,
        );
        _tapButtons = [...values]..shuffle(random);
        _mathOperator = '+';
        _mathLeft = 0;
        _mathRight = 0;
        _mathAnswer = 0;
        break;
      case AlarmMissionType.breathwork:
        _mathOperator = '+';
        _mathLeft = 0;
        _mathRight = 0;
        _mathAnswer = 0;
        _tapButtons = const <int>[];
        break;
    }
  }

  @override
  void dispose() {
    _mathController.dispose();
    super.dispose();
  }

  bool get _canConfirm {
    switch (_mission.type) {
      case AlarmMissionType.breathwork:
        return _breathsCompleted >= _mission.target;
      case AlarmMissionType.mathQuiz:
        return _mathController.text.trim() == _mathAnswer.toString();
      case AlarmMissionType.focusTap:
        return _nextTap > _mission.target;
    }
  }

  double get _progressValue {
    switch (_mission.type) {
      case AlarmMissionType.breathwork:
        return (_breathsCompleted / _mission.target).clamp(0, 1).toDouble();
      case AlarmMissionType.mathQuiz:
        return _canConfirm ? 1.0 : 0.0;
      case AlarmMissionType.focusTap:
        return ((_nextTap - 1) / _mission.target).clamp(0, 1).toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_mission.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_mission.description),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: _progressValue),
          const SizedBox(height: 16),
          _buildMissionContent(context),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canConfirm ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Confirm wakefulness'),
        ),
      ],
    );
  }

  Widget _buildMissionContent(BuildContext context) {
    switch (_mission.type) {
      case AlarmMissionType.breathwork:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Breaths completed: $_breathsCompleted/${_mission.target}'),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () {
                setState(() {
                  if (_breathsCompleted < _mission.target) {
                    _breathsCompleted += 1;
                  }
                });
              },
              child: Text(
                _breathsCompleted >= _mission.target
                    ? 'Mission complete'
                    : 'Record breath ${_breathsCompleted + 1}',
              ),
            ),
          ],
        );
      case AlarmMissionType.mathQuiz:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Solve to continue: $_mathLeft $_mathOperator $_mathRight = ?',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _mathController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Answer',
                errorText: _mathController.text.isEmpty || _canConfirm
                    ? null
                    : 'Keep trying',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        );
      case AlarmMissionType.focusTap:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tap in order: 1 → ${_mission.target}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final value in _tapButtons)
                  FilledButton.tonal(
                    onPressed: () {
                      setState(() {
                        if (value == _nextTap) {
                          _nextTap += 1;
                          _tapError = null;
                        } else {
                          _tapError = 'Tap $_nextTap next';
                        }
                      });
                    },
                    child: Text('$value'),
                  ),
              ],
            ),
            if (_tapError != null) ...[
              const SizedBox(height: 12),
              Text(
                _tapError!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ],
        );
    }
  }
}
