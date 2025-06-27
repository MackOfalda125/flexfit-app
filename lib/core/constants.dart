import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBackground = Color(0xFF1B1B1B);
  static const Color primaryText = Color(0xFFE5E5E5);
  static const Color buttonGreen = Color(0xFF2E7D79);
  static const Color buttonHover = Color(0xFF8BAF94);
  static const Color stopButton = Color(0xFFB04A4A);
  static const Color goodForm = Color(0xFF4CAF50);
  static const Color moderateForm = Color(0xFFFBC02D);
  static const Color poorForm = Color(0xFFE53935);
}

class AppTextStyles {
  static const TextStyle primaryText = TextStyle(
    fontSize: 45,
    color: AppColors.primaryBackground,
    fontWeight: FontWeight.bold,
    fontFamily: 'FiraCode'
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    color: AppColors.primaryText,
    fontWeight: FontWeight.bold,
    fontFamily: 'WorkSans',
  );
}
