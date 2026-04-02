import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';

class AppFonts {
  //Headline H2
  static const TextStyle headline = TextStyle(
    color: Colors.white,
    fontSize: 40,
    fontWeight: FontWeight.bold,
    height: 48 / 40, 
    letterSpacing: -1,
  );
  //Body Paragraph
  static const TextStyle body = TextStyle(
    color: AppColors.blue20,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 20 / 14, 
  );
}