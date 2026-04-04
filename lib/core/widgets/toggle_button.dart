import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/core/widgets/notification_badge.dart';

class ToggleButton extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final Function(int) onToggle;
  final double height;
  final double borderRadius;
  final int? notificationCount;

  const ToggleButton({
    Key? key,
    required this.options,
    required this.selectedIndex,
    required this.onToggle,
    this.height = 32.0,
    this.borderRadius = 16.0, // Скругление 16
    this.notificationCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.black10,
        borderRadius: BorderRadius.circular(borderRadius), // Скругление 16 для всего
      ),
      child: Row(
        children: options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isSelected = index == selectedIndex;
          final isLastOption = index == options.length - 1;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => onToggle(index),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(16), // Скругление 16 для свичей
                  ),
                  child: Center(
                    child: isLastOption && notificationCount != null && notificationCount! > 0
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                option,
                                style: AppFonts.body.copyWith(
                                  color: isSelected ? AppColors.blue100 : AppColors.black60,
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                              SizedBox(width: 8),
                              NotificationBadge(
                                count: notificationCount!,
                                size: 24,
                                activeColor: Colors.white, // Белый фон
                                inactiveColor: Colors.white, // Белый фон для неактивного
                              ),
                            ],
                          )
                        : Text(
                            option,
                            style: AppFonts.body.copyWith(
                              color: isSelected ? AppColors.blue100 : AppColors.black60,
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
