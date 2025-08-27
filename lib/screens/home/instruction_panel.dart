import 'package:app/core/constants.dart';
import 'package:app/services/camera_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InstructionPanel extends StatelessWidget {
  final String exercise;

  const InstructionPanel({super.key, required this.exercise});

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

  // Holds all exercise-related instructions
  static const exerciseInstructions = {
    "squats": {
      "profile": "Stand sideways to the camera",
      "instructions": {0: "", 1: "Keep knees behind toes", 2: "Keep chest up"},
    },
    "bicep curls": {
      "profile": "Stand sideways to the camera",
      "instructions": {
        0: "",
        1: "Keep upper arm vertical",
        2: "Keep body straight",
      },
    },
    "overhead presses": {
      "profile": "Stand facing the camera",
      "instructions": {
        0: "",
        1: "Keep forearms vertical",
        2: "Keep wrists level",
      },
    },
  };

  @override
  Widget build(BuildContext context) {
    final formScore = context.watch<CameraProvider>().formScore ?? 0;
    final percentScore = (formScore * 100).round();
    final instructionId = context.watch<CameraProvider>().instructionId ?? 0;

    final Color scoreColor = _getScoreColor(percentScore);
    final profileInstruction =
        exerciseInstructions[exercise.toLowerCase()]?["profile"] as String? ??
        "";
    final formInstruction =
        (exerciseInstructions[exercise.toLowerCase()]?["instructions"]
            as Map<int, String>?)?[instructionId] ??
        "";

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise,
            style: AppTextStyles.percentageText.copyWith(
              fontSize: 35,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Icon(Icons.camera_alt, size: 18, color: AppColors.primaryText),
              Text(
                profileInstruction,
                style: AppTextStyles.percentageText.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            formInstruction,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.visible,
            softWrap: true,
            style: AppTextStyles.percentageText.copyWith(
              color: scoreColor,
              fontSize: 28,
            ),
          ),
        ],
      ),
    );
  }
}
