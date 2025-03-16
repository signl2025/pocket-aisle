import 'package:permission_handler/permission_handler.dart';

//class for asking permission, requirement for android
class PermissionService {
  static Future<void> requestPermissions() async {
    PermissionStatus storageStatus = await Permission.storage.status;

    if (!storageStatus.isGranted) {
      await Permission.storage.request();
    } 
  }
}
