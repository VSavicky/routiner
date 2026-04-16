import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/core/constants/default_habits.dart';
import 'package:routiner/core/widgets/header.dart';
import 'package:routiner/features/auth/presentation/widgets/auth_header.dart';
import 'package:routiner/features/create_habit/presentation/screens/custom_habit_screen.dart';
import 'package:routiner/features/explore/presentation/widgets/explore_header_widget.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  bool _isBadHabit = false;
  String _moodEmoji = '😊';
  String _moodLabel = 'Good';

  void _refreshHabits() {
    // Callback для обновления привычек
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final habits = DefaultHabits.getByType(!_isBadHabit);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExploreHeaderWidget(header: 'Explore', onPressed: () {}),

          // Заголовок секции с кнопкой VIEW ALL
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Suggested for You',
                  style: AppFonts.bodyTitleMedium.copyWith(
                    color: AppColors.black100,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: Navigate to all habits page
                    print('VIEW ALL pressed');
                  },
                  child: Text(
                    'VIEW ALL',
                    style: AppFonts.bodyAlternative.copyWith(
                      color: AppColors.blue100,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Горизонтальный список карточек привычек
          SizedBox(
            height: 104,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 24),
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                return GestureDetector(
                  onTap: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CustomHabitScreen(
                          isBadHabit: _isBadHabit,
                          moodEmoji: _moodEmoji,
                          moodLabel: _moodLabel,
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
                          onHabitCreated: _refreshHabits,
                        ),
                      ),
                    );
                    if (result != null) {
                      _refreshHabits();
                    }
                  },
                  child: Container(
                    width: 94,
                    height: 104,
                    margin: EdgeInsets.only(
                      right: index < habits.length - 1 ? 12 : 24,
                    ),
                    padding: const EdgeInsets.all(12),
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
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 4),
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
                        const SizedBox(height: 2),
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

          const SizedBox(height: 40),

          // Секция Habit Clubs
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
            child: Text(
              'Habit Clubs',
              style: AppFonts.bodyTitleMedium.copyWith(
                color: AppColors.black100,
              ),
            ),
          ),

          // Горизонтальный список клубов (белые карточки)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 24),
              itemCount: 5,
              itemBuilder: (context, index) {
                final clubs = [
                  {'name': 'Cat Lovers', 'members': '500+', 'emoji': '🐱'},
                  {'name': 'Book Worms', 'members': '1.2k', 'emoji': '📚'},
                  {'name': 'Runners', 'members': '800+', 'emoji': '🏃'},
                  {'name': 'Yoga Life', 'members': '2k', 'emoji': '🧘'},
                  {'name': 'Meditation', 'members': '3k+', 'emoji': '🧠'},
                ];
                final club = clubs[index];
                return GestureDetector(
                  onTap: () {
                    print('Club ${club['name']} tapped');
                  },
                  child: Container(
                    width: 110,
                    height: 120,
                    margin: EdgeInsets.only(right: index < 4 ? 12 : 24),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.black10, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.black10,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(club['emoji']!, style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          club['name']!,
                          style: AppFonts.bodyAlternative.copyWith(
                            color: AppColors.black100,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${club['members']} members',
                          style: AppFonts.bodyAlternative.copyWith(
                            color: AppColors.black60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

