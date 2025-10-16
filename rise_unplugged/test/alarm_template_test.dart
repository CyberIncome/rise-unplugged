import 'package:flutter_test/flutter_test.dart';

import 'package:rise_unplugged/features/alarms/models/alarm_mission.dart';
import 'package:rise_unplugged/features/alarms/services/alarm_templates.dart';

void main() {
  test('Featured templates provide missions and follow-up context', () {
    expect(AlarmTemplateCatalog.featured, isNotEmpty);
    for (final template in AlarmTemplateCatalog.featured) {
      expect(template.mission, isA<AlarmMission>());
      expect(template.recommendedLabel, isNotEmpty);
      expect(template.tags, isNotEmpty);
      for (final followUp in template.followUps) {
        expect(followUp.recommendation, isNotNull);
        expect(followUp.recommendation, isNotEmpty);
      }
    }
  });
}
