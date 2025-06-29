import 'package:flutter/material.dart';
import 'package:app/core/constants.dart';

class StartStopButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isRunning;

  const StartStopButton({
    super.key,
    required this.onTap,
    required this.isRunning,
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
          color: isRunning ? AppColors.stopButton : AppColors.primaryButton,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [AppShadows.buttonShadow],
        ),
        child: Text(
          isRunning ? 'STOP' : 'START',
          style: AppTextStyles.buttonText,
        ),
      ),
    );
  }
}
