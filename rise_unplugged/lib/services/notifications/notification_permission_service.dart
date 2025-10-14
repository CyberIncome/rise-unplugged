import 'package:permission_handler/permission_handler.dart';

class NotificationPermissionService {
  const NotificationPermissionService();

  Future<bool> requestPermissions() async {
    final status = await Permission.notification.status;
    if (status.isGranted) {
      return true;
    }
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  Future<bool> ensureExactAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isGranted) {
      return true;
    }
    final result = await Permission.scheduleExactAlarm.request();
    return result.isGranted;
  }
}
