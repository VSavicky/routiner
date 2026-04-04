import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';

class NotificationBadge extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const NotificationBadge({
    Key? key,
    required this.count,
    this.onTap,
    this.size = 24.0,
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasNotifications = count > 0;
    final displayCount = count > 99 ? '99+' : count.toString();
    final isWhiteBackground = (activeColor ?? AppColors.blue100) == Colors.white;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: hasNotifications 
              ? (activeColor ?? AppColors.blue100) 
              : (inactiveColor ?? AppColors.black10),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: hasNotifications
              ? Text(
                displayCount,
                style: AppFonts.bodyTitleMedium.copyWith( // Body Title Bold
                  color: isWhiteBackground ? AppColors.blue100 : Colors.white,
                  fontSize: size * 0.6, // Пропорционально размеру
                  fontWeight: FontWeight.bold, // Жирный
                ),
              )
              : null,
        ),
      ),
    );
  }
}
