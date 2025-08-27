import 'package:app/core/constants.dart';
import 'package:app/screens/home/exercise_menu_panel/exercise_button.dart';
import 'package:flutter/material.dart';

class ExerciseMenuPanel extends StatelessWidget {
  final VoidCallback onBackPressed;
  final Future<void> Function(String)? onExerciseSelected;

  final List<String> exercises = ["Overhead Presses", "Bicep Curls", "Squats"];

  ExerciseMenuPanel({
    super.key,
    required this.onBackPressed,
    this.onExerciseSelected,
  });

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
                    child: ExerciseButton(
                      label: label,
                      onTap: onExerciseSelected,
                    ),
                  ),
                )
                .toList(),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 12, bottom: 12),
              child: InkWell(
                onTap: onBackPressed,
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.primaryText,
                  size: 38.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
