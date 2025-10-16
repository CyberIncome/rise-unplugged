import 'package:flutter_test/flutter_test.dart';

import 'package:rise_unplugged/features/sleep_debt/models/sleep_session.dart';
import 'package:rise_unplugged/features/sleep_debt/services/sleep_debt_export_service.dart';

void main() {
  group('SleepDebtExportService', () {
    test('buildCsv creates a header and session rows', () {
      const service = SleepDebtExportService();
      final csv = service.buildCsv([
        SleepSession(
          start: DateTime(2024, 1, 1, 22),
          end: DateTime(2024, 1, 2, 6),
        ),
      ]);

      expect(csv.split('\n').first, 'start,end,duration_minutes,source');
      expect(csv.contains('sleep_session_source'), isFalse);
      expect(csv.contains('manual'), isTrue);
      final row = csv.split('\n')[1];
      expect(
        row,
        '2024-01-01T22:00:00.000,2024-01-02T06:00:00.000,480,manual',
      );
    });

    test('shareSessions throws when there are no sessions', () async {
      final service = SleepDebtExportService(shareInvoker: (_, {subject}) async {});

      expect(() => service.shareSessions(const []), throwsA(isA<StateError>()));
    });

    test('shareSessions invokes the provided share handler', () async {
      String? sharedText;
      String? sharedSubject;
      final service = SleepDebtExportService(
        shareInvoker: (text, {subject}) async {
          sharedText = text;
          sharedSubject = subject;
        },
      );

      final sessions = [
        SleepSession(
          start: DateTime(2024, 1, 1, 22),
          end: DateTime(2024, 1, 2, 6),
        ),
      ];

      await service.shareSessions(sessions);

      expect(sharedText, contains('start,end'));
      expect(sharedSubject, 'Rise Unplugged sleep summary');
    });
  });
}
