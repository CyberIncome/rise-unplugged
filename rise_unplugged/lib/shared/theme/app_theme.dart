import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/feature_flags.dart';

enum ThemePreference { system, light, dark }

class AppThemeData {
  AppThemeData({
    required this.lightTheme,
    required this.darkTheme,
    required this.mode,
  });

  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final ThemeMode mode;
}

final appThemeProvider =
    StateNotifierProvider<AppThemeController, AppThemeData>(
  (ref) => AppThemeController(ref),
);

class AppThemeController extends StateNotifier<AppThemeData> {
  AppThemeController(this._ref)
      : super(
          AppThemeData(
            lightTheme: FlexThemeData.light(scheme: FlexScheme.flutterDash),
            darkTheme: FlexThemeData.dark(scheme: FlexScheme.flutterDash),
            mode: ThemeMode.system,
          ),
        ) {
    _load();
    _flagsSubscription = _ref.listen<FeatureFlags>(
      featureFlagsProvider,
      (_, __) => _updateTheme(),
    );
  }

  static const _prefKey = 'theme_preference';
  final Ref _ref;
  late final ProviderSubscription<FeatureFlags> _flagsSubscription;
  ThemePreference _preference = ThemePreference.system;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedValue = prefs.getString(_prefKey);
    if (storedValue != null) {
      _preference = ThemePreference.values.firstWhere(
          (value) => value.name == storedValue,
          orElse: () => ThemePreference.system);
      _updateTheme();
    }
  }

  Future<void> updatePreference(ThemePreference preference) async {
    _preference = preference;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, preference.name);
    _updateTheme();
  }

  void _updateTheme() {
    final flags = _ref.read(featureFlagsProvider);
    final themeMode = switch (_preference) {
      ThemePreference.dark => ThemeMode.dark,
      ThemePreference.light => ThemeMode.light,
      ThemePreference.system => ThemeMode.system,
    };

    final baseLight = FlexThemeData.light(
      scheme: FlexScheme.flutterDash,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
    );
    final baseDark = FlexThemeData.dark(
      scheme: FlexScheme.flutterDash,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
    );

    final theme = AppThemeData(
      lightTheme: baseLight.copyWith(
        pageTransitionsTheme: _pageTransitions,
      ),
      darkTheme: baseDark.copyWith(
        pageTransitionsTheme: _pageTransitions,
      ),
      mode: themeMode,
    );

    if (flags.isAestheticRefreshEnabled) {
      state = theme;
    } else {
      state = AppThemeData(
        lightTheme: baseLight,
        darkTheme: baseDark,
        mode: themeMode,
      );
    }
  }

  PageTransitionsTheme get _pageTransitions => const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
        },
      );

  @override
  void dispose() {
    _flagsSubscription.close();
    super.dispose();
  }
}
