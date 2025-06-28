import 'package:flutter/material.dart';
import 'package:app/core/constants.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  //TODO: Camera Permission, Load Models

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
            LoadingAnimationWidget.discreteCircle(
              color: AppColors.secondaryButton,
              size: 80,
              secondRingColor: AppColors.secondaryButton,
              thirdRingColor: AppColors.primaryBackground,
            ),
          ],
        ),
      ),
    );
  }
}
