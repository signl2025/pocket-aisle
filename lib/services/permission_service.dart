import 'package:permission_handler/permission_handler.dart';

//class for asking permission, requirement for android
class PermissionService {
  static Future<void> requestPermissions() async {
    PermissionStatus storageStatus = await Permission.storage.status;
    PermissionStatus audioStatus = await Permission.audio.status;
    PermissionStatus videoStatus = await Permission.videos.status;

    if (!storageStatus.isGranted) {
      await Permission.storage.request();
    } 
    if (!audioStatus.isGranted) {
      await Permission.audio.request();
    } 
    if (!videoStatus.isGranted) {
      await Permission.videos.request();
    } 
  }
}
