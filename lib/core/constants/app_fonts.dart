import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';

class AppFonts {
  //Headline H2
  static const TextStyle headlineH2 = TextStyle(
    color: Colors.white,
    fontSize: 40,
    fontWeight: FontWeight.bold,
    height: 48 / 40, 
    letterSpacing: -1,
  );
  
  //Headline H5
  static const TextStyle headlineH5 = TextStyle(
    color: AppColors.black100,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 32 / 24, 
    letterSpacing: -0.5,
  );
  
  //Body Paragraph
  static const TextStyle body = TextStyle(
    color: AppColors.blue20,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 20 / 14, 
    letterSpacing: 0,
  );
  
  //Body Title Medium
  static const TextStyle bodyTitleMedium = TextStyle(
    color: AppColors.black100,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 24 / 18,
    letterSpacing: 1,
  );
  
  //Body Medium
  static const TextStyle bodyMedium = TextStyle(
    color: AppColors.black100,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 24 / 18,
    letterSpacing: 0,
  );
  
  //Body Title Medium (для пустого поля)
  static const TextStyle bodyTitleMediumEmpty = TextStyle(
    color: AppColors.black20,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 24 / 18,
    letterSpacing: 0,
  );
}