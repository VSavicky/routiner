import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';

/// Виджет для отображения дней челленджа (Day 1, Day 2, Day 3...)
/// Вместо календарных дат показывает порядковые номера дней челленджа
class ChallengeDaysList extends StatelessWidget {
  final int totalDays; // Общее количество дней челленджа
  final int selectedDay; // Выбранный день (1-based)
  final Function(int) onDaySelected; // Callback с номером дня
  final Map<int, double> dailyProgress; // Прогресс по дням (0.0-1.0)

  const ChallengeDaysList({
    Key? key,
    required this.totalDays,
    required this.selectedDay,
    required this.onDaySelected,
    this.dailyProgress = const {},
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 95,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalDays,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (context, index) {
          final dayNumber = index + 1;
          final isSelected = dayNumber == selectedDay;
          final progress = dailyProgress[dayNumber] ?? 0.0;
          final isCompleted = progress >= 1.0;

          return GestureDetector(
            onTap: () => onDaySelected(dayNumber),
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Circular progress with day number
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background circle
                        Container(
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppColors.blue.withOpacity(0.3)
                                : isCompleted 
                                    ? AppColors.green.withOpacity(0.15)
                                    : Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                        // Circular progress indicator
                        Padding(
                          padding: const EdgeInsets.all(3),
                          child: CircularProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            strokeWidth: 3,
                            backgroundColor: Colors.white.withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted 
                                  ? AppColors.green 
                                  : progress > 0 
                                      ? AppColors.orange 
                                      : Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                        // Day number in center
                        Center(
                          child: Text(
                            '$dayNumber',
                            style: AppFonts.bodyAlternative.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isSelected 
                                  ? Colors.white 
                                  : isCompleted 
                                      ? AppColors.green
                                      : Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                        // Checkmark for completed days
                        if (isCompleted)
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: AppColors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Day label
                  Text(
                    'Day',
                    style: AppFonts.bodyAlternative.copyWith(
                      fontSize: 10,
                      color: isSelected 
                          ? Colors.white.withOpacity(0.9)
                          : isCompleted
                              ? AppColors.green.withOpacity(0.9)
                              : Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
