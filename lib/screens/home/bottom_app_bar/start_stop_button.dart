import 'package:app/core/constants.dart';
import 'package:app/services/camera_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StartStopButton extends StatelessWidget {
  const StartStopButton({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isTracking = context.select<CameraProvider, bool>(
      (p) => p.isStreaming,
    );

    return InkWell(
      onTap: () => context.read<CameraProvider>().toggleTracking(),
      child: Container(
        height: 38.40,
        width: 70,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isTracking ? AppColors.stopButton : AppColors.primaryButton,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [AppShadows.buttonShadow],
        ),
        child: Text(
          isTracking ? 'STOP' : 'START',
          style: AppTextStyles.buttonText,
        ),
      ),
    );
  }
}
