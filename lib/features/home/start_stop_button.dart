import 'package:app/core/constants.dart';
import 'package:flutter/material.dart';

class StartStopButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isTracking;

  const StartStopButton({
    super.key,
    required this.onTap,
    required this.isTracking,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
