import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';

class NotificationIcon extends StatelessWidget {
  final IconData icon;
  final bool hasNotification;
  final VoidCallback onTap;
  final double? size;
  final Color? iconColor;
  final Color? notificationColor;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;

  const NotificationIcon({
    Key? key,
    required this.icon,
    required this.hasNotification,
    required this.onTap,
    this.size = 24.0,
    this.iconColor,
    this.notificationColor = Colors.red,
    this.showBorder = true,
    this.borderColor,
    this.borderWidth = 2.0,
    this.borderRadius = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: showBorder
            ? BoxDecoration(
                border: Border.all(
                  color: borderColor ?? AppColors.black10,
                  width: borderWidth,
                ),
                borderRadius: BorderRadius.circular(borderRadius),
              )
            : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Основная иконка
            Center(
              child: Icon(
                icon,
                size: size,
                color: iconColor ?? AppColors.black40,
              ),
            ),
            // Красная точка уведомления
            if (hasNotification)
              Positioned(
                right: 4, // Смещение вправо
                top: 4,  // Смещение вверх
                child: Container(
                  width: 12,  // Размер точки
                  height: 12,
                  decoration: BoxDecoration(
                    color: notificationColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5, // Белая обводка для контраста
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
