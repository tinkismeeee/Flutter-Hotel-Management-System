import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFFEFEFE);
  static const Color surface = Color(0xFFF6F8FB);
  static const Color field = Color(0xFFF6F6F6);
  static const Color border = Color(0xFFE8EAEC);

  static const Color textPrimary = Color(0xFF171725);
  static const Color textSecondary = Color(0xFF434E58);
  static const Color textMuted = Color(0xFF78828A);
  static const Color hint = Color(0xFF9CA4AB);

  static const Color primary = Color(0xFF2852AF);
  static const Color primaryAlt = Color(0xFF2853AF);
  static const Color danger = Color(0xFFF41F52);
  static const Color success = Color(0xFF1A9C5B);
  static const Color warning = Color(0xFFF59E0B);
}

class CustomColors {
  static const Color loginHintText = AppColors.hint;
  static const Color loginText = AppColors.textPrimary;
  static const Color forgotPasswordText = AppColors.danger;
  static const Color buttonBackground = AppColors.primaryAlt;
  static const Color buttonText = AppColors.background;
  static const Color signUpFieldText = AppColors.textMuted;
  static const Color globalBackground = AppColors.background;
  static const Color loginSmallText = AppColors.textSecondary;
  static const Color loginTextFieldBackground = AppColors.hint;
}
