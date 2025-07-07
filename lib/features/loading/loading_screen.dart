import 'package:flutter/material.dart';
import 'package:app/core/constants.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:app/features/home/home_screen.dart';
import 'package:app/services/permissions.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  //TODO: Camera Permission, Load Models

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _handlePermissionsAndNavigate();

    // Future.delayed(const Duration(seconds: 2), () {
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(builder: (context) => const HomeScreen()),
    //   );
    // });
  }

  Future<void> _handlePermissionsAndNavigate() async {
    bool granted = await PermissionsUtil.checkAndRequestCameraPermission(context);
    if (!mounted) return;
    if (granted) {
      // Navigate after 2 seconds if permission is granted
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      });
    }
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
