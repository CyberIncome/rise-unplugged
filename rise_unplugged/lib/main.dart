import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'features/onboarding/onboarding_controller.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/settings/settings_screen.dart';
import 'services/background/background_task_service.dart';
import 'services/native_timezone.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureTimeZones();
  runApp(const ProviderScope(child: RiseUnpluggedApp()));
}

Future<void> _configureTimeZones() async {
  try {
    tz.initializeTimeZones();
    final timezoneName = await NativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneName));
  } catch (_) {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  }
}

class RiseUnpluggedApp extends ConsumerWidget {
  const RiseUnpluggedApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);
    final onboardingStatus = ref.watch(onboardingControllerProvider);
    ref.watch(backgroundTaskServiceProvider);

    final routes = <String, WidgetBuilder>{
      AppShell.routeName: (_) => const AppShell(),
      OnboardingFlow.routeName: (_) => const OnboardingFlow(),
      SettingsScreen.routeName: (_) => const SettingsScreen(),
    };

    return onboardingStatus.when(
      data: (completed) => MaterialApp(
        title: 'Rise Unplugged',
        theme: theme.lightTheme,
        darkTheme: theme.darkTheme,
        themeMode: theme.mode,
        debugShowCheckedModeBanner: false,
        initialRoute: completed ? AppShell.routeName : OnboardingFlow.routeName,
        supportedLocales: const [Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routes: routes,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case OnboardingFlow.routeName:
              return MaterialPageRoute<void>(
                builder: (_) => const OnboardingFlow(),
              );
            case SettingsScreen.routeName:
              return MaterialPageRoute<void>(
                builder: (_) => const SettingsScreen(),
              );
            case AppShell.routeName:
            default:
              return MaterialPageRoute<void>(
                builder: (_) => const AppShell(),
              );
          }
        },
      ),
      loading: () => MaterialApp(
        theme: theme.lightTheme,
        darkTheme: theme.darkTheme,
        themeMode: theme.mode,
        routes: routes,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => MaterialApp(
        theme: theme.lightTheme,
        darkTheme: theme.darkTheme,
        themeMode: theme.mode,
        routes: routes,
        home: Scaffold(
          body: Center(
            child: Text('Something went wrong: $error'),
          ),
        ),
      ),
    );
  }
}
