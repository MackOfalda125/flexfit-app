import 'package:app/core/constants.dart';
import 'package:app/services/camera_provider.dart';
import 'package:app/services/native_inference_channel.dart';
import 'package:app/utils/permissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

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

        final cameraProvider = Provider.of<CameraProvider>(
          context,
          listen: false,
        );
        await cameraProvider.initCamera();
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
    // New model loading (native inference channel)
    try {
      final success = await NativeInferenceChannel.initializeModel();
      if (!success) {
        throw Exception("Failed to initialize MoveNet model");
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(currentContext, '/home');
    } catch (e) {
      debugPrint('Error initializing MoveNet model: $e');
      if (!mounted) return;
      showModelLoadingError(currentContext, e.toString());
    }

    // Old model loading (flutter asset)
    // try {
    //   final modelBytes = await rootBundle.load(
    //     'assets/models/movenet_singlepose_lightning.tflite',
    //   );
    //   final modelBytesList = modelBytes.buffer.asUint8List();
    //
    //   await MoveNetIsolateController().initialize(modelBytesList);
    //
    //   // Navigate to home screen after initialization
    //   if (!mounted) return;
    //
    //   Navigator.pushReplacementNamed(currentContext, '/home');
    // } catch (e) {
    //   debugPrint('Error initializing MoveNet model: $e');
    // }

    // TODO: Load  Exercise Models
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
        backgroundColor: AppColors.primaryBackground,
        title: Text(
          "Permission Denied",
          style: AppTextStyles.buttonText.copyWith(fontSize: 20),
        ),
        content: Text(
          "Please allow camera permission to proceed.",
          style: AppTextStyles.buttonText,
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primaryButton,
              foregroundColor: AppColors.primaryText,
            ),
            child: Text("Try Again", style: AppTextStyles.buttonText),
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
        backgroundColor: AppColors.primaryBackground,
        title: Text(
          "Permission Permanently Denied",
          style: AppTextStyles.buttonText.copyWith(fontSize: 20),
        ),
        content: Text(
          "Go to app settings to enable camera.",
          style: AppTextStyles.buttonText,
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppColors.secondaryButton,
              foregroundColor: AppColors.primaryText,
            ),
            child: Text("Open Settings", style: AppTextStyles.buttonText),
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void showModelLoadingError(BuildContext context, String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.primaryBackground,
        title: Text(
          "Model Loading Error",
          style: AppTextStyles.buttonText.copyWith(fontSize: 20),
        ),
        content: Text(
          "Failed to load MoveNet Model.",
          style: AppTextStyles.buttonText,
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primaryButton,
              foregroundColor: AppColors.primaryText,
            ),
            child: Text("Try Again", style: AppTextStyles.buttonText),
            onPressed: () {
              Navigator.of(context).pop();
              _initApp();
            },
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppColors.stopButton,
              foregroundColor: AppColors.primaryText,
            ),
            child: Text("Exit", style: AppTextStyles.buttonText),
            onPressed: () {
              Navigator.of(context).pop();
              SystemNavigator.pop();
            },
          ),
        ],
      ),
    );
  }
}
