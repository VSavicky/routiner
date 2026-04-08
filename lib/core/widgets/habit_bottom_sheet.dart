import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/features/create_habit/presentation/screens/custom_habit_screen.dart';

class HabitBottomSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String iconPath;
  final bool isBadHabbit;
  final VoidCallback onClose;
  final String? moodEmoji;
  final String? moodLabel;

  const HabitBottomSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconPath,
    required this.isBadHabbit,
    required this.onClose,
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
                  isBadHabbit ? 'Quit Bad Habbit' : 'New Good Habbit',
                  style: AppFonts.bodyAlternative.copyWith(
                    fontSize: 10,
                    color: AppColors.black40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                SizedBox(height: 8),
                
                // Контейнер для создания привычки
                GestureDetector(
                  onTap: () {
                    onClose();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CustomHabitScreen(
                          isBadHabit: isBadHabbit,
                          moodEmoji: moodEmoji,
                          moodLabel: moodLabel,
                        ),
                      ),
                    );
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
                          'Create Custom Habbit',
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
              'POPULAR HABITS',
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
              itemCount: 5,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    onClose();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CustomHabitScreen(
                          isBadHabit: isBadHabbit,
                          moodEmoji: moodEmoji,
                          moodLabel: moodLabel,
                          selectedHabitName: _getHabitName(index),
                          selectedHabitSubtitle: _getHabitSubtitle(index),
                          selectedHabitEmoji: _getHabitEmoji(index),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 140,
                    margin: EdgeInsets.only(right: index < 4 ? 12 : 24), // Отступ для последней карточки
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getPastelColor(index),
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
                                _getHabitEmoji(index),
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          
                          Spacer(),
                          
                          
                        ],
                      ),
                      
                      SizedBox(height: 4), // Уменьшил с 8 до 4
                      
                      // Название привычки
                      Text(
                        _getHabitName(index),
                        style: AppFonts.bodyTitleMedium.copyWith(
                          color: AppColors.black100,
                          fontSize: 14, // Уменьшил с 18 до 14
                        ),
                      ),
                      
                      SizedBox(height: 2), // Уменьшил с 4 до 2
                      
                      // Подпись
                      Text(
                        _getHabitSubtitle(index),
                        style: AppFonts.bodyAlternative.copyWith(
                          fontSize: 10, // Уменьшил с 12 до 10
                          color: AppColors.black60,
                        ),
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

  // Методы для данных популярных привычек
  Color _getPastelColor(int index) {
    List<Color> pastelColors = [
      Color(0xFFFFB3BA),  // Светло-голубой
      Color(0xFFB3E5FC),  // Светло-фиолетовый  
      Color(0xFFFFB3BA),  // Светло-розовый
      Color(0xFFB3FFB3),  // Светло-зеленый
      Color(0xFFE5B3FF),  // Светло-бирюзовый
    ];
    return pastelColors[index % pastelColors.length];
  }

  String _getHabitEmoji(int index) {
    List<String> emojis = ['🚶', '📚', '💧', '🧘', '🏃'];
    return emojis[index % emojis.length];
  }

  String _getHabitName(int index) {
    List<String> names = ['Walk', 'Read', 'Drink Water', 'Meditate', 'Run'];
    return names[index % names.length];
  }

  String _getHabitSubtitle(int index) {
    List<String> subtitles = ['10 km', '30 min', '2L', '15 min', '5 km'];
    return subtitles[index % subtitles.length];
  }
}
