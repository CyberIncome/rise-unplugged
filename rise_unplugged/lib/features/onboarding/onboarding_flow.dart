import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/gradient_background.dart';
import '../../shared/widgets/primary_button.dart';
import '../../services/notifications/notification_permission_service.dart';
import '../alarms/providers/alarm_schedule_provider.dart';
import '../sleep_debt/models/sleep_persona.dart';
import '../sleep_debt/providers/sleep_debt_provider.dart';
import 'onboarding_controller.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  static const routeName = '/onboarding';

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final PageController _controller = PageController();
  int _index = 0;
  bool _isCompleting = false;
  SleepChronotype? _chronotype;
  WakeChallenge? _wakeChallenge;
  MorningFocus? _morningFocus;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _OnboardingPage(
        title: 'Rested mornings',
        subtitle:
            'Personalised wake windows and gentle follow-up prompts keep you on rhythm.',
        icon: Icons.alarm_rounded,
      ),
      const _OnboardingPage(
        title: 'Understand your sleep debt',
        subtitle:
            'Track weekly rest, debts, and wins with science-backed insights.',
        icon: Icons.auto_graph_rounded,
      ),
      const _OnboardingPage(
        title: 'Unplug with intention',
        subtitle:
            'Focus on calm rituals before the day begins with mindful timers.',
        icon: Icons.spa_rounded,
      ),
      _PersonaFormPage(
        chronotype: _chronotype,
        challenge: _wakeChallenge,
        focus: _morningFocus,
        onChronotypeChanged: (value) => setState(() => _chronotype = value),
        onChallengeChanged: (value) => setState(() => _wakeChallenge = value),
        onFocusChanged: (value) => setState(() => _morningFocus = value),
      ),
    ];

    final isLastPage = _index == pages.length - 1;
    final canComplete = !isLastPage ||
        (_chronotype != null &&
            _wakeChallenge != null &&
            _morningFocus != null);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemCount: pages.length,
                  itemBuilder: (_, index) => pages[index],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < pages.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: i == _index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: i == _index ? 0.9 : 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: PrimaryButton(
                  label: isLastPage
                      ? (_isCompleting ? 'Preparing...' : 'Finish setup')
                      : 'Next',
                  onPressed: _isCompleting || (isLastPage && !canComplete)
                      ? null
                      : () {
                          if (isLastPage) {
                            unawaited(_completeOnboarding(context, ref));
                          } else {
                            _controller.animateToPage(
                              _index + 1,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeOnboarding(BuildContext context, WidgetRef ref) async {
    setState(() => _isCompleting = true);
    final notifier = ref.read(alarmScheduleProvider.notifier);
    await notifier.bootstrap();
    await const NotificationPermissionService().requestPermissions();
    await const NotificationPermissionService().ensureExactAlarmPermission();
    if (_chronotype != null &&
        _wakeChallenge != null &&
        _morningFocus != null) {
      await ref.read(sleepDebtProvider.notifier).setPersona(
            SleepPersona(
              chronotype: _chronotype!,
              challenge: _wakeChallenge!,
              morningFocus: _morningFocus!,
            ),
          );
    }
    await ref.read(onboardingControllerProvider.notifier).markComplete();
    if (!mounted || !context.mounted) {
      return;
    }
    setState(() => _isCompleting = false);
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppShell.routeName);
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 96, color: theme.colorScheme.secondary),
        const SizedBox(height: 32),
        Text(
          title,
          style: theme.textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            subtitle,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _PersonaFormPage extends StatelessWidget {
  const _PersonaFormPage({
    required this.chronotype,
    required this.challenge,
    required this.focus,
    required this.onChronotypeChanged,
    required this.onChallengeChanged,
    required this.onFocusChanged,
  });

  final SleepChronotype? chronotype;
  final WakeChallenge? challenge;
  final MorningFocus? focus;
  final ValueChanged<SleepChronotype> onChronotypeChanged;
  final ValueChanged<WakeChallenge> onChallengeChanged;
  final ValueChanged<MorningFocus> onFocusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tailor your mornings',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We\'ll use these to personalise sleep debt insights, alarm missions, and unplug rituals.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text('Your chronotype', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final option in SleepChronotype.values)
                ChoiceChip(
                  label: Text(option.label),
                  selected: chronotype == option,
                  onSelected: (_) => onChronotypeChanged(option),
                ),
            ],
          ),
          if (chronotype != null) ...[
            const SizedBox(height: 8),
            Text(
              chronotype!.summary,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 24),
          Text('Biggest wake-up challenge', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final option in WakeChallenge.values)
                ChoiceChip(
                  label: Text(option.label),
                  selected: challenge == option,
                  onSelected: (_) => onChallengeChanged(option),
                ),
            ],
          ),
          if (challenge != null) ...[
            const SizedBox(height: 8),
            Text(
              challenge!.insight,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 24),
          Text('Morning focus', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final option in MorningFocus.values)
                ChoiceChip(
                  label: Text(option.label),
                  selected: focus == option,
                  onSelected: (_) => onFocusChanged(option),
                ),
            ],
          ),
          if (focus != null) ...[
            const SizedBox(height: 8),
            Text(
              focus!.ritualSuggestion,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
