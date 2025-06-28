import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBackground = Color(0xFF1B1B1B);
  static const Color primaryText = Color(0xFFE5E5E5);
  static const Color primaryButton = Color(0xFF2E7D59);
  static const Color secondaryButton = Color(0xFF8BAF94);
  static const Color primaryShadow = Color(0x3F7286A0);
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

  static const TextStyle percentageText = TextStyle(
      fontSize: 45,
      color: AppColors.primaryText,
      fontWeight: FontWeight.bold,
      fontFamily: 'FiraCode'
  );

  static const TextStyle percentageSymbol = TextStyle(
      fontSize: 25,
      color: AppColors.primaryText,
      fontFamily: 'FiraCode'
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    color: AppColors.primaryText,
    fontWeight: FontWeight.bold,
    fontFamily: 'WorkSans',
  );
}

class AppShadows {
  static const BoxShadow appBarShadow = BoxShadow(
    color: AppColors.primaryShadow,
    blurRadius: 4,
    offset: Offset(0, 0),
    spreadRadius: 3,
  );

  static const BoxShadow semiCircleShadow = BoxShadow(
    color: Color(0x40000000),
    blurRadius: 4,
    offset: Offset(0, 0),
    spreadRadius: 3,
  );

  static const BoxShadow buttonShadow = BoxShadow(
    color: AppColors.primaryShadow,
    blurRadius: 6,
    offset: Offset(0, 2),
    spreadRadius: 1,
  );
}


