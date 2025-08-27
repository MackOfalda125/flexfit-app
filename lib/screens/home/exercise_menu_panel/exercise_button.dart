import 'package:app/core/constants.dart';
import 'package:flutter/material.dart';

class ExerciseButton extends StatelessWidget {
  final String label;
  final Future<void> Function(String)? onTap;

  const ExerciseButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (onTap != null) {
          await onTap!(label);
        }
      },
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
