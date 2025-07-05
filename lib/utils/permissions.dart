import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsUtil {
  static Future<bool> checkAndRequestCameraPermission(
    BuildContext context,
  ) async {
    var status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    } else if (status.isDenied || status.isRestricted) {
      var result = await Permission.camera.request();
      if (result.isGranted) return true;

      _showDeniedDialog(context);
      return false;
    } else if (status.isPermanentlyDenied) {
      _showPermanentlyDeniedDialog(context);
      return false;
    }
    return false;
  }

  static void _showDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Permission Denied"),
        content: const Text("Please allow camera permission to proceed."),
        actions: [
          TextButton(
            child: const Text("Try Again"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  static void _showPermanentlyDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Permission Permanently Denied"),
        content: const Text("Go to app settings to enable camera."),
        actions: [
          TextButton(
            child: const Text("Open Settings"),
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
