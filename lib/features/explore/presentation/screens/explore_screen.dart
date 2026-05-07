import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/core/constants/default_habits.dart';
import 'package:routiner/core/widgets/header.dart';
import 'package:routiner/features/auth/presentation/widgets/auth_header.dart';
import 'package:routiner/features/create_habit/presentation/screens/custom_habit_screen.dart';
import 'package:routiner/features/explore/presentation/widgets/explore_header_widget.dart';
import 'package:routiner/features/challenges/presentation/screens/challenges_list_screen.dart';
import 'package:routiner/features/challenges/presentation/screens/challenge_detail_screen.dart';
import 'package:routiner/features/habits/presentation/screens/habits_list_screen.dart';
import 'package:routiner/features/learning/presentation/screens/learning_detail_screen.dart';
import 'package:routiner/features/learning/presentation/screens/learning_list_screen.dart';
import 'package:routiner/features/clubs/presentation/screens/clubs_list_screen.dart';
import 'package:routiner/features/clubs/presentation/screens/club_detail_screen.dart';

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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const HabitsListScreen(),
                      ),
                    );
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ClubsListScreen(),
                      ),
                    );
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
                  {
                    'id': 'cat_lovers',
                    'name': 'Cat Lovers',
                    'description': 'Build daily habits while celebrating our feline friends',
                    'emoji': '🐱',
                    'members': '500+',
                    'color': const Color(0xFFFF6B6B),
                    'habits': [
                      {'title': 'Morning pet care', 'emoji': '�', 'targetValue': 15, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
                      {'title': 'Cat feeding routine', 'emoji': '🥫', 'targetValue': 2, 'targetUnit': 'times', 'incrementStep': 1, 'habitType': 'build'},
                      {'title': 'Play with cat', 'emoji': '🎾', 'targetValue': 20, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
                    ],
                  },
                  {
                    'id': 'book_worms',
                    'name': 'Book Worms',
                    'description': 'Cultivate reading habits and expand your knowledge daily',
                    'emoji': '📚',
                    'members': '1.2k',
                    'color': const Color(0xFF4ECDC4),
                    'habits': [
                      {'title': 'Daily reading', 'emoji': '�', 'targetValue': 30, 'targetUnit': 'min', 'incrementStep': 10, 'habitType': 'build'},
                      {'title': 'Book notes', 'emoji': '📝', 'targetValue': 1, 'targetUnit': 'page', 'incrementStep': 1, 'habitType': 'build'},
                      {'title': 'Library visit', 'emoji': '🏛️', 'targetValue': 1, 'targetUnit': 'visit', 'incrementStep': 1, 'habitType': 'build'},
                    ],
                  },
                  {
                    'id': 'runners',
                    'name': 'Runners',
                    'description': 'Build consistent running habits and achieve your fitness goals',
                    'emoji': '🏃',
                    'members': '800+',
                    'color': const Color(0xFF95E1D3),
                    'habits': [
                      {'title': 'Morning run', 'emoji': '🏃', 'targetValue': 5, 'targetUnit': 'km', 'incrementStep': 1, 'habitType': 'build'},
                      {'title': 'Stretching', 'emoji': '🤸', 'targetValue': 10, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
                      {'title': 'Hydration', 'emoji': '💧', 'targetValue': 8, 'targetUnit': 'glasses', 'incrementStep': 1, 'habitType': 'build'},
                    ],
                  },
                  {
                    'id': 'yoga_life',
                    'name': 'Yoga Life',
                    'description': 'Transform your life through daily yoga and mindfulness practices',
                    'emoji': '🧘',
                    'members': '2k',
                    'color': const Color(0xFFA8E6CF),
                    'habits': [
                      {'title': 'Morning yoga', 'emoji': '🧘', 'targetValue': 20, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
                      {'title': 'Meditation', 'emoji': '🧠', 'targetValue': 10, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
                      {'title': 'Breathing exercises', 'emoji': '🌬️', 'targetValue': 5, 'targetUnit': 'min', 'incrementStep': 1, 'habitType': 'build'},
                    ],
                  },
                  {
                    'id': 'meditation',
                    'name': 'Meditation',
                    'description': 'Find inner peace and build mental clarity through meditation',
                    'emoji': '🧠',
                    'members': '3k+',
                    'color': const Color(0xFFC7CEEA),
                    'habits': [
                      {'title': 'Daily meditation', 'emoji': '�', 'targetValue': 15, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
                      {'title': 'Mindful breathing', 'emoji': '🌬️', 'targetValue': 10, 'targetUnit': 'min', 'incrementStep': 2, 'habitType': 'build'},
                      {'title': 'Gratitude journal', 'emoji': '📔', 'targetValue': 3, 'targetUnit': 'items', 'incrementStep': 1, 'habitType': 'build'},
                    ],
                  },
                ];
                final club = clubs[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ClubDetailScreen(
                          club: club,
                        ),
                      ),
                    );
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
                            child: Text(club['emoji'] as String, style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          club['name'] as String,
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ChallengesListScreen(),
                      ),
                    );
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
                final now = DateTime.now();
                final challenges = [
                  {
                    'id': '7_day_water',
                    'title': '7-Day Water Challenge',
                    'endTime': now.add(const Duration(days: 7)),
                    'description': 'Start your wellness journey with proper hydration. Drink 8 glasses of water daily for one week.',
                    'icon': '💧',
                    'color': const Color(0xFF29B6F6),
                    'participants': 128,
                    'habits': [
                      {'title': 'Drink water', 'icon': '💧', 'targetValue': 8, 'targetUnit': 'glasses', 'incrementStep': 1, 'habitType': 'build'},
                    ],
                  },
                  {
                    'id': '21_day_fitness',
                    'title': '21-Day Fitness Kickstart',
                    'endTime': now.add(const Duration(days: 21)),
                    'description': 'Build a consistent workout habit in just 3 weeks.',
                    'icon': '🏃',
                    'color': const Color(0xFF5B6EFC),
                    'participants': 256,
                    'habits': [
                      {'title': 'Daily workout', 'icon': '💪', 'targetValue': 20, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
                      {'title': 'Take 8K steps', 'icon': '🚶', 'targetValue': 8000, 'targetUnit': 'steps', 'incrementStep': 1000, 'habitType': 'build'},
                    ],
                  },
                  {
                    'id': 'morning_routine',
                    'title': 'Perfect Morning Routine',
                    'endTime': now.add(const Duration(days: 14)),
                    'description': 'Transform your mornings and set the tone for productive days.',
                    'icon': '🌅',
                    'color': const Color(0xFFFFA726),
                    'participants': 89,
                    'habits': [
                      {'title': 'Meditate', 'icon': '🧘', 'targetValue': 10, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
                      {'title': 'Morning stretch', 'icon': '🤸', 'targetValue': 5, 'targetUnit': 'min', 'incrementStep': 1, 'habitType': 'build'},
                    ],
                  },
                ];
                final challenge = challenges[index];
                final endTime = challenge['endTime'] as DateTime;
                final timeLeft = endTime.difference(DateTime.now());
                final days = timeLeft.inDays;
                final hours = timeLeft.inHours.remainder(24);
                final timeLeftText = days > 0 ? '$days days ${hours}h left' : '$hours hours left';
                
                return GestureDetector(
                  onTap: () {
                    // Создаем полную копию данных челленджа для ChallengeDetailScreen
                    final fullChallengeData = Map<String, dynamic>.from(challenge);
                    // Добавляем недостающие поля, которые ожидает ChallengeDetailScreen
                    fullChallengeData['startDate'] = now.subtract(const Duration(days: 1)).toIso8601String();
                    fullChallengeData['endDate'] = (challenge['endTime'] as DateTime).toIso8601String();
                    
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChallengeDetailScreen(
                          challenge: fullChallengeData,
                          onJoinChanged: () {
                            // Callback при изменении состояния присоединения
                          },
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 200,
                    height: 160,
                    margin: EdgeInsets.only(right: index < 2 ? 12 : 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          challenge['color'] as Color,
                          (challenge['color'] as Color).withOpacity(0.8),
                        ],
                        stops: [0.0, 1.0],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Иконка эмодзи челленджа
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              challenge['icon'] as String,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Заголовок с эмодзи
                        Text(
                          '${challenge['title']} ${challenge['icon']}',
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
                          timeLeftText,
                          style: AppFonts.bodyAlternative.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Количество привычек
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.task_alt,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(challenge['habits'] as List<dynamic>?)?.length ?? 1} habits',
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LearningListScreen(),
                      ),
                    );
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

          // Горизонтальный список уроков Learning
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 24),
              itemCount: 3,
              itemBuilder: (context, index) {
                final lessons = [
                  {
                    'id': 'water_benefits',
                    'title': 'Hydration Science',
                    'subtitle': 'Why water is essential',
                    'emoji': '💧',
                    'duration': '5 min read',
                    'difficulty': 'Beginner',
                    'color': const Color(0xFF29B6F6),
                    'readTime': 5,
                  },
                  {
                    'id': 'walking_benefits',
                    'title': 'Walking for Wellness',
                    'subtitle': 'Transform your health with daily walks',
                    'emoji': '🚶',
                    'duration': '8 min read',
                    'difficulty': 'Beginner',
                    'color': const Color(0xFF66BB6A),
                    'readTime': 8,
                  },
                  {
                    'id': 'morning_routine',
                    'title': 'Perfect Morning',
                    'subtitle': 'Build a routine for success',
                    'emoji': '🌅',
                    'duration': '12 min read',
                    'difficulty': 'Intermediate',
                    'color': const Color(0xFFFFA726),
                    'readTime': 12,
                  },
                ];
                final lesson = lessons[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => LearningDetailScreen(
                          lesson: lesson,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 200,
                    height: 180,
                    margin: EdgeInsets.only(right: index < 2 ? 12 : 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          lesson['color'] as Color,
                          (lesson['color'] as Color).withOpacity(0.8),
                        ],
                        stops: [0.0, 1.0],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Верхняя часть с эмодзи
                        Expanded(
                          flex: 3,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                lesson['emoji'] as String,
                                style: const TextStyle(fontSize: 48),
                              ),
                            ),
                          ),
                        ),
                        // Нижняя часть с информацией
                        Expanded(
                          flex: 2,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Заголовок
                                Text(
                                  lesson['title'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                // Подзаголовок
                                Text(
                                  lesson['subtitle'] as String,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                // Метаданные
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        lesson['difficulty'] as String,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      lesson['duration'] as String,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 8,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
