import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/core/constants/default_habits.dart';
import 'package:routiner/features/create_habit/presentation/screens/custom_habit_screen.dart';
import 'package:routiner/l10n/app_localizations.dart';

class HabitBottomSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String iconPath;
  final bool isBadHabbit;
  final VoidCallback onClose;
  final VoidCallback? onHabitCreated; // Callback при создании привычки
  final String? moodEmoji;
  final String? moodLabel;

  const HabitBottomSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconPath,
    required this.isBadHabbit,
    required this.onClose,
    this.onHabitCreated,
    this.moodEmoji,
    this.moodLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ручка для свайпа
          Container(
            margin: EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.black20,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Основной контент
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                
                // Заголовок
                Text(
                  title,
                  style: AppFonts.bodyAlternative.copyWith(
                    fontSize: 10,
                    color: AppColors.black40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                SizedBox(height: 8),
                
                // Контейнер для создания привычки
                GestureDetector(
                  onTap: () async {
                    onClose();
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CustomHabitScreen(
                          isBadHabit: isBadHabbit,
                          moodEmoji: moodEmoji,
                          moodLabel: moodLabel,
                          onHabitCreated: onHabitCreated,
                        ),
                      ),
                    );
                    // Если привычка создана, вызываем callback
                    if (result != null && onHabitCreated != null) {
                      onHabitCreated!();
                    }
                  },
                  child: Container(
                    height: 70,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.black10,
                        width: 1,
                      ),
                    ),
                  child: Row(
                    children: [
                      // Текст слева
                      Expanded(
                        child: Text(
                          context.l10n.translate('createCustomHabit'),
                          style: AppFonts.bodyTitleMedium.copyWith(
                            color: AppColors.black100,
                          ),
                        ),
                      ),
                      
                      // Иконка справа
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.black10,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.add,
                          color: AppColors.black100,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
                
                SizedBox(height: 16),
                Text(
              context.l10n.translate('popularHabits'),
              style: AppFonts.bodyAlternative.copyWith(
                fontSize: 10,
                color: AppColors.black40,
                fontWeight: FontWeight.bold,
              ),
              ),
              ],
            ),
          ),
          

          
          
          SizedBox(height: 16),
          
          // Список карточек на всю ширину (без ограничений Column)
          SizedBox(
            height: 102,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: 24), // Только левый отступ
              itemCount: DefaultHabits.getByType(!isBadHabbit).length,
              itemBuilder: (context, index) {
                final habit = DefaultHabits.getByType(!isBadHabbit)[index];
                return GestureDetector(
                  onTap: () async {
                    onClose();
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CustomHabitScreen(
                          isBadHabit: isBadHabbit,
                          moodEmoji: moodEmoji,
                          moodLabel: moodLabel,
                          selectedHabitName: habit.name,
                          selectedHabitSubtitle: habit.subtitle,
                          selectedHabitEmoji: habit.emoji,
                          selectedHabitColor: habit.color,
                          targetValue: habit.targetValue,
                          targetUnit: habit.targetUnit,
                          motivation: habit.motivation,
                          frequency: habit.frequency,
                          period: habit.period,
                          reminderTime: habit.reminderTime,
                          defaultHabitId: habit.id,
                          onHabitCreated: onHabitCreated,
                        ),
                      ),
                    );
                    // Если привычка создана, вызываем callback
                    if (result != null && onHabitCreated != null) {
                      onHabitCreated!();
                    }
                  },
                  child: Container(
                    width: 94,
                    height: 104,
                    margin: EdgeInsets.only(right: index < DefaultHabits.getByType(!isBadHabbit).length - 1 ? 12 : 24),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: habit.color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Верхняя часть с иконкой
                      Row(
                        children: [
                          // Квадрат с иконкой
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                habit.emoji,
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          
                          Spacer(),
                          
                          
                        ],
                      ),
                      
                      SizedBox(height: 4),
                      
                      // Название привычки
                      Text(
                        habit.name,
                        style: AppFonts.bodyTitleMedium.copyWith(
                          color: AppColors.black100,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: 2),
                      
                      // Подпись
                      Text(
                        habit.subtitle,
                        style: AppFonts.bodyAlternative.copyWith(
                          fontSize: 10,
                          color: AppColors.black60,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
          
          SizedBox(height: 40),
        ],
      ),
    );
  }

}
