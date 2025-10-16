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
  final TextEditingController _affirmationController = TextEditingController();
  bool _affirmationComplete = false;
  String? _affirmationError;
  bool _manualComplete = false;
  int _loggedSteps = 0;

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
      case AlarmMissionType.affirmation:
      case AlarmMissionType.barcodeScan:
      case AlarmMissionType.photoProof:
      case AlarmMissionType.stepCounter:
      case AlarmMissionType.memoryGrid:
      case AlarmMissionType.breathAndAffirm:
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
    _affirmationController.dispose();
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
      case AlarmMissionType.affirmation:
        return _affirmationComplete;
      case AlarmMissionType.barcodeScan:
      case AlarmMissionType.photoProof:
      case AlarmMissionType.memoryGrid:
        return _manualComplete;
      case AlarmMissionType.stepCounter:
        return _loggedSteps >= _mission.target;
      case AlarmMissionType.breathAndAffirm:
        return _breathsCompleted >= _mission.target && _affirmationComplete;
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
      case AlarmMissionType.affirmation:
        return _affirmationComplete
            ? 1.0
            : (_affirmationController.text.trim().isEmpty ? 0.0 : 0.5);
      case AlarmMissionType.barcodeScan:
      case AlarmMissionType.photoProof:
      case AlarmMissionType.memoryGrid:
        return _manualComplete ? 1.0 : 0.0;
      case AlarmMissionType.stepCounter:
        final target = _mission.target == 0 ? 1 : _mission.target;
        return (_loggedSteps / target).clamp(0, 1).toDouble();
      case AlarmMissionType.breathAndAffirm:
        final breathProgress =
            (_breathsCompleted / (_mission.target == 0 ? 1 : _mission.target))
                .clamp(0, 1)
                .toDouble();
        final affirmationProgress = _affirmationComplete
            ? 1.0
            : (_affirmationController.text.trim().isEmpty ? 0.0 : 0.5);
        return (breathProgress + affirmationProgress) / 2;
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
        return _buildBreathworkSection(context);
      case AlarmMissionType.mathQuiz:
        return _buildMathSection(context);
      case AlarmMissionType.focusTap:
        return _buildFocusTapSection(context);
      case AlarmMissionType.affirmation:
        return _buildAffirmationSection(context);
      case AlarmMissionType.barcodeScan:
        return _buildManualConfirmationSection(
          context,
          buttonLabel: 'I scanned the barcode',
        );
      case AlarmMissionType.photoProof:
        return _buildManualConfirmationSection(
          context,
          buttonLabel: 'Photo captured',
        );
      case AlarmMissionType.stepCounter:
        return _buildStepCounterSection(context);
      case AlarmMissionType.memoryGrid:
        return _buildManualConfirmationSection(
          context,
          buttonLabel: 'Pattern complete',
        );
      case AlarmMissionType.breathAndAffirm:
        return _buildBreathAndAffirmSection(context);
    }
  }

  Widget _buildBreathworkSection(BuildContext context) {
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
  }

  Widget _buildMathSection(BuildContext context) {
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
  }

  Widget _buildFocusTapSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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

  Widget _buildAffirmationSection(BuildContext context, {bool showCues = true}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Speak your affirmation out loud, then type it below to lock it in.',
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _affirmationController,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Personal affirmation',
            errorText: _affirmationError,
          ),
          onChanged: (_) {
            setState(() {
              _affirmationComplete = false;
              _affirmationError = null;
            });
          },
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: () {
            final text = _affirmationController.text.trim();
            setState(() {
              if (text.length >= 8) {
                _affirmationComplete = true;
                _affirmationError = null;
              } else {
                _affirmationComplete = false;
                _affirmationError =
                    'Make it at least 8 characters to commit.';
              }
            });
          },
          child: Text(
            _affirmationComplete ? 'Affirmation locked' : 'Commit affirmation',
          ),
        ),
        if (_affirmationComplete)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Great! Repeat it once more before you confirm.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        if (showCues && _mission.cues.isNotEmpty) ...[
          const SizedBox(height: 12),
          ..._buildCueWidgets(),
        ],
      ],
    );
  }

  Widget _buildManualConfirmationSection(
    BuildContext context, {
    required String buttonLabel,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_mission.cues.isNotEmpty) ...[
          ..._buildCueWidgets(),
          const SizedBox(height: 12),
        ],
        FilledButton.tonal(
          onPressed: () {
            setState(() {
              _manualComplete = !_manualComplete;
            });
          },
          child: Text(_manualComplete ? 'Marked complete' : buttonLabel),
        ),
        if (_manualComplete)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Nice work! Tap again if you need to reset.',
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _buildStepCounterSection(BuildContext context) {
    final target = _mission.target == 0 ? 1 : _mission.target;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Log your movement until you reach $target steps.'),
        const SizedBox(height: 8),
        Slider(
          value: _loggedSteps.clamp(0, target).toDouble(),
          max: target.toDouble(),
          divisions: target,
          label: '$_loggedSteps',
          onChanged: (value) {
            setState(() {
              _loggedSteps = value.round();
            });
          },
        ),
        Text('Steps logged: $_loggedSteps / $target'),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: () {
            setState(() {
              _loggedSteps = target;
            });
          },
          child: Text(
            _loggedSteps >= target ? 'Steps complete' : 'Mark steps complete',
          ),
        ),
        if (_mission.cues.isNotEmpty) ...[
          const SizedBox(height: 12),
          ..._buildCueWidgets(),
        ],
      ],
    );
  }

  Widget _buildBreathAndAffirmSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBreathworkSection(context),
        const SizedBox(height: 16),
        _buildAffirmationSection(context, showCues: false),
        if (_mission.cues.isNotEmpty) ...[
          const SizedBox(height: 12),
          ..._buildCueWidgets(),
        ],
      ],
    );
  }

  List<Widget> _buildCueWidgets() {
    return _mission.cues
        .map(
          (cue) => Padding(
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
        )
        .toList(growable: false);
  }
}
