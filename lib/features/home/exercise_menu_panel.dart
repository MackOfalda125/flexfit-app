import 'package:flutter/material.dart';
import 'package:app/core/constants.dart';
import 'package:app/features/home/exercise_button.dart';

class ExerciseMenuPanel extends StatelessWidget {
  final VoidCallback onBackPressed;

  final List<String> exercises = [
    "Overhead Presses",
    "Pull-ups",
    "Bench Presses",
    "Bicep Curls",
    "Squats",
    "Lunges",
    "Deadlifts",
  ];

  ExerciseMenuPanel({super.key, required this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 6),
      height: MediaQuery.of(context).size.height,
      width: 216,
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        boxShadow: [AppShadows.panelShadow],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: exercises
                .map(
                  (label) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: ExerciseButton(label: label),
                  ),
                )
                .toList(),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 12, bottom: 12),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.primaryText,
                  size: 38.4,
                ),
                onPressed: onBackPressed,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
