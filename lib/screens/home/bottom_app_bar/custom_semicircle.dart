import 'package:app/core/constants.dart';
import 'package:app/services/camera_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomSemicircle extends StatelessWidget {
  const CustomSemicircle({super.key});

  Color _getScoreColor(int score) {
    if (score == 0) {
      return AppColors.primaryShadow;
    } else if (score >= 70) {
      return AppColors.goodForm;
    } else if (score >= 50) {
      return AppColors.moderateForm;
    } else {
      return AppColors.poorForm;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formScore = context.watch<CameraProvider>().formScore ?? 0;
    final percentScore = (formScore * 100).round();
    final scoreColor = _getScoreColor(percentScore);

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Outer semicircle (border)
        Container(
          width: 160,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryBackground,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(100),
              topRight: Radius.circular(100),
            ),
            boxShadow: [AppShadows.semiCircleShadow],
          ),
        ),
        // Inner semicircle (fill)
        Container(
          padding: EdgeInsets.only(top: 10),
          width: 146,
          height: 73,
          decoration: BoxDecoration(
            color: scoreColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(100),
              topRight: Radius.circular(100),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Text(
                  percentScore.toString(),
                  style: AppTextStyles.percentageText,
                ),
              ),
              const Positioned(
                right: 13,
                top: 20,
                bottom: 0,
                child: Text("%", style: AppTextStyles.percentageSymbol),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
