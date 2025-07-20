import 'package:permission_handler/permission_handler.dart';

enum CameraPermissionStatus { granted, denied, permanentlyDenied }

class PermissionsUtil {
  static Future<CameraPermissionStatus>
  checkAndRequestCameraPermission() async {
    var status = await Permission.camera.status;

    if (status.isGranted) {
      return CameraPermissionStatus.granted;
    } else if (status.isDenied || status.isRestricted) {
      var result = await Permission.camera.request();
      return result.isGranted
          ? CameraPermissionStatus.granted
          : CameraPermissionStatus.denied;
    } else if (status.isPermanentlyDenied) {
      return CameraPermissionStatus.permanentlyDenied;
    }
    return CameraPermissionStatus.denied;
  }
}
