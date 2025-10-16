import 'dart:async';
import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeatureFlags {
  const FeatureFlags({
    this.enableAiInsights = false,
    this.enableStreaks = false,
    this.enableExports = false,
    this.isAestheticRefreshEnabled = true,
  });

  final bool enableAiInsights;
  final bool enableStreaks;
  final bool enableExports;
  final bool isAestheticRefreshEnabled;

  FeatureFlags copyWith({
    bool? enableAiInsights,
    bool? enableStreaks,
    bool? enableExports,
    bool? isAestheticRefreshEnabled,
  }) {
    return FeatureFlags(
      enableAiInsights: enableAiInsights ?? this.enableAiInsights,
      enableStreaks: enableStreaks ?? this.enableStreaks,
      enableExports: enableExports ?? this.enableExports,
      isAestheticRefreshEnabled:
          isAestheticRefreshEnabled ?? this.isAestheticRefreshEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableAiInsights': enableAiInsights,
      'enableStreaks': enableStreaks,
      'enableExports': enableExports,
      'isAestheticRefreshEnabled': isAestheticRefreshEnabled,
    };
  }

  factory FeatureFlags.fromJson(Map<String, dynamic> json) {
    return FeatureFlags(
      enableAiInsights: json['enableAiInsights'] as bool? ?? false,
      enableStreaks: json['enableStreaks'] as bool? ?? false,
      enableExports: json['enableExports'] as bool? ?? false,
      isAestheticRefreshEnabled:
          json['isAestheticRefreshEnabled'] as bool? ?? true,
    );
  }
}

final featureFlagsProvider =
    NotifierProvider<FeatureFlagsController, FeatureFlags>(
  FeatureFlagsController.new,
);

class FeatureFlagsController extends Notifier<FeatureFlags> {
  static const _storageKey = 'feature_flags';

  @override
  FeatureFlags build() {
    unawaited(_load());
    return const FeatureFlags();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored == null) {
      return;
    }
    final decoded = jsonDecode(stored) as Map<String, dynamic>;
    state = FeatureFlags.fromJson(decoded);
  }

  Future<void> setAiInsights(bool enabled) =>
      _update(state.copyWith(enableAiInsights: enabled));

  Future<void> setStreaks(bool enabled) =>
      _update(state.copyWith(enableStreaks: enabled));

  Future<void> setExports(bool enabled) =>
      _update(state.copyWith(enableExports: enabled));

  Future<void> setAestheticRefresh(bool enabled) =>
      _update(state.copyWith(isAestheticRefreshEnabled: enabled));

  Future<void> _update(FeatureFlags value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(value.toJson()));
  }
}
