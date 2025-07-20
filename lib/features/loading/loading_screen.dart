import 'package:app/core/constants.dart';
import 'package:app/services/movenet/movenet_isolate_controller.dart';
import 'package:app/utils/permissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:permission_handler/permission_handler.dart';

//TODO: Match dialog styles with the rest of the app

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Store context before async operations
    final BuildContext currentContext = context;

    // Camera Permission
    final permission = await PermissionsUtil.checkAndRequestCameraPermission();
    if (!mounted) return;

    switch (permission) {
      case CameraPermissionStatus.granted:
        debugPrint("Camera permission granted");
        break;
      case CameraPermissionStatus.denied:
        debugPrint("Camera permission denied");
        showDeniedDialog(currentContext);
        return;
      case CameraPermissionStatus.permanentlyDenied:
        debugPrint("Camera permission permanently denied");
        showPermanentlyDeniedDialog(currentContext);
        return;
    }

    // Load MoveNet model
    try {
      final modelBytes = await rootBundle.load(
        'assets/models/movenet_singlepose_lightning.tflite',
      );
      final modelBytesList = modelBytes.buffer.asUint8List();

      await MoveNetIsolateController().initialize(modelBytesList);

      if (!mounted) return;

      Navigator.pushReplacementNamed(currentContext, '/home');
    } catch (e) {
      debugPrint('Error initializing MoveNet model: $e');
    }

    //TODO: Load  Exercise Models
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryText,
      extendBodyBehindAppBar: true,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("LOGO", style: AppTextStyles.primaryText),
            SizedBox(height: 130),
            RepaintBoundary(
              key: const ValueKey('loading_boundary'),
              child: LoadingAnimationWidget.discreteCircle(
                color: AppColors.secondaryButton,
                size: 80,
                secondRingColor: AppColors.secondaryButton,
                thirdRingColor: AppColors.primaryBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showDeniedDialog(BuildContext context) {
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

  static void showPermanentlyDeniedDialog(BuildContext context) {
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
