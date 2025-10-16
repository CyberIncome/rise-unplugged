import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../models/sleep_session.dart';

typedef ShareInvoker = Future<void> Function(
  String text, {
  String? subject,
});

class SleepDebtExportService {
  const SleepDebtExportService({ShareInvoker? shareInvoker})
      : _shareInvoker = shareInvoker ?? Share.share;

  final ShareInvoker _shareInvoker;

  Future<void> shareSessions(List<SleepSession> sessions) async {
    if (sessions.isEmpty) {
      throw StateError('No sessions to export.');
    }
    final csv = buildCsv(sessions);
    await _shareInvoker(
      csv,
      subject: 'Rise Unplugged sleep summary',
    );
  }

  @visibleForTesting
  String buildCsv(List<SleepSession> sessions) {
    final buffer = StringBuffer()
      ..writeln('start,end,duration_minutes,source');
    for (final session in sessions) {
      final duration = session.duration.inMinutes;
      buffer.writeln(
        '${session.start.toIso8601String()},'
        '${session.end.toIso8601String()},'
        '$duration,'
        '${session.source.name}',
      );
    }
    return buffer.toString();
  }
}
