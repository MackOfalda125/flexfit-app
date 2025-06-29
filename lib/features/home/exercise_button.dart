import 'package:flutter/material.dart';
import 'package:app/core/constants.dart';

class ExerciseButton extends StatelessWidget {
  final String label;

  const ExerciseButton({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Container(
        width: 192,
        height: 38,
        decoration: ShapeDecoration(
          color: AppColors.primaryButton,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          shadows: [AppShadows.buttonShadow],
        ),
        child: Center(child: Text(label, style: AppTextStyles.buttonText)),
      ),
    );
  }
}
