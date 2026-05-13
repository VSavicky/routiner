import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum HabitType {
  quitBad,
  newGood,
}


class HabitOptionWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String iconPath;
  final HabitType type;
  final VoidCallback onTap;

  const HabitOptionWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconPath,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Текст слева
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black100,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.black40,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(width: 6),
            
            // Иконка справа
            Container(
              width: 20,
              height: 20,
              child: SvgPicture.asset(
                iconPath,
                width: 16,
                height: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
