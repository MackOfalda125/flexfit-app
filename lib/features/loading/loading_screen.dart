import 'package:app/core/constants.dart';
import 'package:app/features/home/home_screen.dart';
import 'package:app/services/movenet_service.dart';
import 'package:app/services/permissions.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

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
    // Camera Permission
    bool granted = await PermissionsUtil.checkAndRequestCameraPermission(
      context,
    );
    if (!mounted || !granted) return;

    // Load MoveNet model
    try {
      await MoveNetService().loadModel();
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      debugPrint('Error loading MoveNet model: $e');
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
}
