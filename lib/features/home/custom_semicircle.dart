import 'package:flutter/material.dart';
import 'package:app/core/constants.dart';

class CustomSemicircle extends StatelessWidget {
  final int score;

  const CustomSemicircle({super.key, required this.score});

  Color _getScoreColor(int score) {
    if (score >= 85) {
      return AppColors.goodForm;
    } else if (score >= 60) {
      return AppColors.moderateForm;
    } else {
      return AppColors.poorForm;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor(score);

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
              Center(child: Text(score.toString(), style: AppTextStyles.percentageText)),
              const Positioned(
                  right: 13,
                  top: 20,
                  bottom: 0,
                  child: Text("%", style: AppTextStyles.percentageSymbol,))
            ],
          ),
        ),
      ],
    );
  }
}
