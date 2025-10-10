import 'dart:async';

import '../../features/sleep_debt/models/sleep_session.dart';

abstract class HealthIntegrationService {
  Future<bool> isAvailable();
  Future<bool> requestPermissions();
  Future<List<SleepSession>> fetchRecentSessions();
}

class AppleHealthIntegrationService implements HealthIntegrationService {
  const AppleHealthIntegrationService();

  @override
  Future<List<SleepSession>> fetchRecentSessions() async {
    // In a production build this would use health_kit_reporter or similar package.
    return [];
  }

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> requestPermissions() async => false;
}

class GoogleFitIntegrationService implements HealthIntegrationService {
  const GoogleFitIntegrationService();

  @override
  Future<List<SleepSession>> fetchRecentSessions() async {
    // In a production build this would use google_fit or health packages.
    return [];
  }

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> requestPermissions() async => false;
}
