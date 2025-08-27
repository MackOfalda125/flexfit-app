import 'package:app/core/constants.dart';
import 'package:app/services/camera_provider.dart';
import 'package:app/services/native_inference_channel.dart';
import 'package:app/utils/permissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    try {
      final success = await NativeInferenceChannel.initializeModel();
      if (!success) {
        throw Exception("Failed to initialize MoveNet model");
      }
    } catch (e) {
      debugPrint('Error initializing MoveNet model: $e');
      if (!mounted) return;
      showModelLoadingError(currentContext, e.toString());
      return;
    }

    // Initialize exercise-specific model
    try {
      final exerciseInit = await NativeInferenceChannel.initExerciseModel(
        'overhead presses',
      );
      if (!exerciseInit) {
        throw Exception("Failed to initialize exercise model");
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(currentContext, '/home');
    } catch (e) {
      debugPrint('Error initializing exercise model: $e');
      if (!mounted) return;
      showModelLoadingError(currentContext, e.toString());
    }
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
          "Failed to load Models.",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      extendBodyBehindAppBar: true,
      body: Center(
        child: RepaintBoundary(
          key: const ValueKey('loading_boundary'),
          // Insert gif loading animation
          child: Image.asset(
            "assets/images/flexfit_loading.gif",
            width: 200,
            height: 200,
          ),
        ),
      ),
    );
  }
}
