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
      body: SingleChildScrollView(
        child: Column(
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Habit Clubs',
                  style: AppFonts.bodyTitleMedium.copyWith(
                    color: AppColors.black100,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    print('VIEW ALL clubs pressed');
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

          // Секция Challenges
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Challenges',
                  style: AppFonts.bodyTitleMedium.copyWith(
                    color: AppColors.black100,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    print('VIEW ALL challenges pressed');
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

          // Горизонтальный список челленджей
          SizedBox(
            height: 175,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 24),
              itemCount: 3,
              itemBuilder: (context, index) {
                final challenges = [
                  {
                    'title': 'Best Runners!',
                    'emoji': '🏃',
                    'timeLeft': '5 days 13 hours left',
                    'friends': 2,
                    'progress': 0.6,
                  },
                  {
                    'title': 'Best Bikers!',
                    'emoji': '🚴',
                    'timeLeft': '2 days 11 hours left',
                    'friends': 1,
                    'progress': 0.4,
                  },
                  {
                    'title': 'Yoga Masters',
                    'emoji': '🧘',
                    'timeLeft': '7 days left',
                    'friends': 3,
                    'progress': 0.8,
                  },
                ];
                final challenge = challenges[index];
                return GestureDetector(
                  onTap: () {
                    print('Challenge ${challenge['title']} tapped');
                  },
                  child: Container(
                    width: 200,
                    height: 160,
                    margin: EdgeInsets.only(right: index < 2 ? 12 : 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.purple,
                          AppColors.blue,
                        ],
                        stops: [0.0, 1.0],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Часы иконка
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.access_time,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Заголовок с эмодзи
                        Text(
                          '${challenge['title']} ${challenge['emoji']}',
                          style: AppFonts.bodyAlternative.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Осталось времени
                        Text(
                          challenge['timeLeft'] as String,
                          style: AppFonts.bodyAlternative.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Прогресс бар
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: challenge['progress'] as double,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Аватарки друзей
                        Row(
                          children: [
                            // Стек аватарок
                            SizedBox(
                              width: 40,
                              height: 24,
                              child: Stack(
                                children: [
                                  for (int i = 0; i < (challenge['friends'] as int).clamp(0, 2); i++)
                                    Positioned(
                                      left: i * 16.0,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.purple,
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          size: 14,
                                          color: AppColors.black60,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${challenge['friends']} friends joined',
                              style: AppFonts.bodyAlternative.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 40),

          // Секция Learning
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Learning',
                  style: AppFonts.bodyTitleMedium.copyWith(
                    color: AppColors.black100,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    print('VIEW ALL learning pressed');
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

          // Горизонтальный список статей Learning
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 24),
              itemCount: 3,
              itemBuilder: (context, index) {
                final articles = [
                  {
                    'title': 'Why should we drink water often?',
                    'emoji': '💧',
                  },
                  {
                    'title': 'Benefits of regular walking',
                    'emoji': '🚶',
                  },
                  {
                    'title': 'Morning routine for success',
                    'emoji': '🌅',
                  },
                ];
                final article = articles[index];
                return GestureDetector(
                  onTap: () {
                    print('Article ${article['title']} tapped');
                  },
                  child: Container(
                    width: 200,
                    height: 180,
                    margin: EdgeInsets.only(right: index < 2 ? 12 : 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.purple,
                          AppColors.blue,
                        ],
                        stops: [0.0, 1.0],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Верхняя часть с эмодзи (заглушка для изображения)
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                article['emoji']!,
                                style: const TextStyle(fontSize: 48),
                              ),
                            ),
                          ),
                        ),
                        // Нижняя синяя часть с заголовком
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AppColors.blue,
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Иконка документа
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.article,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Заголовок статьи
                              Expanded(
                                child: Text(
                                  article['title']!,
                                  style: AppFonts.bodyAlternative.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
    ),
    );
  }
}
