import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/core/constants/default_habits.dart';
import 'package:routiner/core/widgets/header.dart';
import 'package:routiner/l10n/app_localizations.dart';
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

  String _getLocalizedHabitName(String habitId, BuildContext context) {
    switch (habitId) {
      case 'walk':
        return context.l10n.translate('walk');
      case 'read':
        return context.l10n.translate('read');
      case 'water':
        return context.l10n.translate('drinkWater');
      case 'meditate':
        return context.l10n.translate('meditate');
      case 'run':
        return context.l10n.translate('run');
      case 'sleep':
        return context.l10n.translate('sleepEarly');
      case 'workout':
        return context.l10n.translate('workout');
      case 'journal':
        return context.l10n.translate('journal');
      case 'smoke':
        return context.l10n.translate('quitSmoking');
      case 'sugar':
        return context.l10n.translate('lessSugar');
      case 'social':
        return context.l10n.translate('lessSocialMedia');
      case 'alcohol':
        return context.l10n.translate('noAlcohol');
      case 'procrastinate':
        return context.l10n.translate('stopProcrastinating');
      default:
        return habitId; // Возвращаем ID если нет маппинга
    }
  }

  String _getLocalizedHabitSubtitle(String habitId, BuildContext context) {
    switch (habitId) {
      case 'walk':
        return '10,000 ${context.l10n.translate('steps')}';
      case 'read':
        return '30 ${context.l10n.translate('pages')}';
      case 'water':
        return '2,000 ${context.l10n.translate('ml')}';
      case 'meditate':
        return '15 ${context.l10n.translate('min')}';
      case 'run':
        return '5 ${context.l10n.translate('km')}';
      case 'sleep':
        return '8 ${context.l10n.translate('hours')}';
      case 'workout':
        return '45 ${context.l10n.translate('min')}';
      case 'journal':
        return '1 ${context.l10n.translate('entry')}';
      case 'smoke':
        return '0 ${context.l10n.translate('cigarettes')}';
      case 'sugar':
        return 'Max 25${context.l10n.translate('cal')}';
      case 'social':
        return 'Max 30 ${context.l10n.translate('min')}';
      case 'alcohol':
        return '0 ${context.l10n.translate('drinks')}';
      case 'procrastinate':
        return '${context.l10n.translate('completeTasks')}';
      default:
        return ''; // Возвращаем пустую строку если нет маппинга
    }
  }

  String _getLocalizedClubName(String clubId, BuildContext context) {
    switch (clubId) {
      case 'cat_lovers':
        return context.l10n.translate('catLovers');
      case 'book_worms':
        return context.l10n.translate('bookWorms');
      case 'runners':
        return context.l10n.translate('runners');
      case 'yoga_life':
        return context.l10n.translate('yogaLife');
      case 'meditation':
        return context.l10n.translate('meditationClub');
      case 'fitness_gurus':
        return context.l10n.translate('fitnessGurus');
      case 'creative_minds':
        return context.l10n.translate('creativeMinds');
      case 'eco_warriors':
        return context.l10n.translate('ecoWarriors');
      default:
        return clubId; // Возвращаем ID если нет маппинга
    }
  }

  String _getLocalizedClubDescription(String clubId, BuildContext context) {
    switch (clubId) {
      case 'cat_lovers':
        return context.l10n.translate('catLoversDescription');
      case 'book_worms':
        return context.l10n.translate('bookWormsDescription');
      case 'runners':
        return context.l10n.translate('runnersDescription');
      case 'yoga_life':
        return context.l10n.translate('yogaLifeDescription');
      case 'meditation':
        return context.l10n.translate('meditationClubDescription');
      case 'fitness_gurus':
        return context.l10n.translate('fitnessGurusDescription');
      case 'creative_minds':
        return context.l10n.translate('creativeMindsDescription');
      case 'eco_warriors':
        return context.l10n.translate('ecoWarriorsDescription');
      default:
        return ''; // Возвращаем пустую строку если нет маппинга
    }
  }

  String _getLocalizedChallengeTitle(String challengeId, BuildContext context) {
    switch (challengeId) {
      case '7_day_water':
        return context.l10n.translate('sevenDayWaterChallenge');
      case '21_day_fitness':
        return context.l10n.translate('twentyOneDayFitnessKickstart');
      case 'morning_routine':
        return context.l10n.translate('perfectMorningRoutine');
      default:
        return '';
    }
  }

  String _getLocalizedChallengeDescription(String challengeId, BuildContext context) {
    switch (challengeId) {
      case '7_day_water':
        return context.l10n.translate('sevenDayWaterChallengeDescription');
      case '21_day_fitness':
        return context.l10n.translate('twentyOneDayFitnessKickstartDescription');
      case 'morning_routine':
        return context.l10n.translate('perfectMorningRoutineDescription');
      default:
        return '';
    }
  }

  String _getLocalizedLessonTitle(String lessonId, BuildContext context) {
    switch (lessonId) {
      case 'water_benefits':
        return context.l10n.translate('hydrationScience');
      case 'walking_benefits':
        return context.l10n.translate('walkingForWellness');
      case 'morning_routine':
        return context.l10n.translate('perfectMorning');
      default:
        return '';
    }
  }

  String _getLocalizedLessonSubtitle(String lessonId, BuildContext context) {
    switch (lessonId) {
      case 'water_benefits':
        return context.l10n.translate('hydrationScienceSubtitle');
      case 'walking_benefits':
        return context.l10n.translate('walkingForWellnessSubtitle');
      case 'morning_routine':
        return context.l10n.translate('perfectMorningSubtitle');
      default:
        return '';
    }
  }

  String _getLocalizedLessonDifficulty(String difficulty, BuildContext context) {
    switch (difficulty) {
      case 'Beginner':
        return context.l10n.translate('beginner');
      case 'Intermediate':
        return context.l10n.translate('intermediate');
      default:
        return difficulty; // Возвращаем оригинал если нет маппинга
    }
  }

  void _refreshHabits() {
    // Callback для обновления привычек
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final habits = DefaultHabits.getByType(!_isBadHabit).map((habit) {
      // Локализуем название и subtitle привычки
      return DefaultHabit(
        id: habit.id,
        name: _getLocalizedHabitName(habit.id, context),
        emoji: habit.emoji,
        subtitle: _getLocalizedHabitSubtitle(habit.id, context),
        color: habit.color,
        targetValue: habit.targetValue,
        targetUnit: habit.targetUnit,
        unitLabel: habit.unitLabel,
        frequency: habit.frequency,
        period: habit.period,
        isGoodHabit: habit.isGoodHabit,
        motivation: habit.motivation,
        reminderTime: habit.reminderTime,
      );
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExploreHeaderWidget(header: context.l10n.translate('explore'), onPressed: () {}),

          // Заголовок секции с кнопкой VIEW ALL
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.translate('suggestedForYou'),
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
                    context.l10n.translate('viewAll'),
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
                          moodLabel: context.l10n.translate('good'),
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
                  context.l10n.translate('habitClubs'),
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
                    context.l10n.translate('viewAll'),
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
                    'name': context.l10n.translate('catLovers'),
                    'description': context.l10n.translate('catLoversDescription'),
                    'emoji': '🐱',
                    'members': '500+',
                    'color': const Color(0xFFFF6B6B),
                    'habits': [
                      {'title': context.l10n.translate('morningPetCareHabit'), 'emoji': '🐾', 'targetValue': 15, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
                      {'title': context.l10n.translate('catFeedingRoutineHabit'), 'emoji': '🥫', 'targetValue': 2, 'targetUnit': 'times', 'incrementStep': 1, 'habitType': 'build'},
                      {'title': context.l10n.translate('playWithCatHabit'), 'emoji': '🎾', 'targetValue': 20, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
                    ],
                  },
                  {
                    'id': 'book_worms',
                    'name': context.l10n.translate('bookWorms'),
                    'description': context.l10n.translate('bookWormsDescription'),
                    'emoji': '📚',
                    'members': '1.2k',
                    'color': const Color(0xFF4ECDC4),
                    'habits': [
                      {'title': context.l10n.translate('dailyReadingHabit2'), 'emoji': '📖', 'targetValue': 30, 'targetUnit': 'min', 'incrementStep': 10, 'habitType': 'build'},
                      {'title': context.l10n.translate('bookNotesHabit'), 'emoji': '📝', 'targetValue': 1, 'targetUnit': 'page', 'incrementStep': 1, 'habitType': 'build'},
                      {'title': context.l10n.translate('libraryVisitHabit'), 'emoji': '🏛️', 'targetValue': 1, 'targetUnit': 'visit', 'incrementStep': 1, 'habitType': 'build'},
                    ],
                  },
                  {
                    'id': 'runners',
                    'name': context.l10n.translate('runners'),
                    'description': context.l10n.translate('runnersDescription'),
                    'emoji': '🏃',
                    'members': '800+',
                    'color': const Color(0xFF95E1D3),
                    'habits': [
                      {'title': context.l10n.translate('morningRunHabit'), 'emoji': '🏃', 'targetValue': 5, 'targetUnit': 'km', 'incrementStep': 1, 'habitType': 'build'},
                      {'title': context.l10n.translate('stretchingHabit'), 'emoji': '🤸', 'targetValue': 10, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
                      {'title': context.l10n.translate('hydrationHabit'), 'emoji': '💧', 'targetValue': 8, 'targetUnit': 'glasses', 'incrementStep': 1, 'habitType': 'build'},
                    ],
                  },
                  {
                    'id': 'yoga_life',
                    'name': context.l10n.translate('yogaLife'),
                    'description': context.l10n.translate('yogaLifeDescription'),
                    'emoji': '🧘',
                    'members': '2k',
                    'color': const Color(0xFFA8E6CF),
                    'habits': [
                      {'title': context.l10n.translate('morningYogaHabit'), 'emoji': '🧘', 'targetValue': 20, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
                      {'title': context.l10n.translate('meditationHabit'), 'emoji': '🧠', 'targetValue': 10, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
                      {'title': context.l10n.translate('breathingExercisesHabit'), 'emoji': '🌬️', 'targetValue': 5, 'targetUnit': 'min', 'incrementStep': 1, 'habitType': 'build'},
                    ],
                  },
                  {
                    'id': 'meditation',
                    'name': context.l10n.translate('meditationClub'),
                    'description': context.l10n.translate('meditationClubDescription'),
                    'emoji': '🧠',
                    'members': '3k+',
                    'color': const Color(0xFFC7CEEA),
                    'habits': [
                      {'title': context.l10n.translate('dailyMeditationHabit'), 'emoji': '🧘', 'targetValue': 15, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
                      {'title': context.l10n.translate('mindfulBreathingHabit'), 'emoji': '🌬️', 'targetValue': 10, 'targetUnit': 'min', 'incrementStep': 2, 'habitType': 'build'},
                      {'title': context.l10n.translate('gratitudeJournalHabit'), 'emoji': '📔', 'targetValue': 3, 'targetUnit': 'items', 'incrementStep': 1, 'habitType': 'build'},
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
                          _getLocalizedClubName(club['id'] as String, context),
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
                          '${club['members']} ${context.l10n.translate('members')}',
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
                  context.l10n.translate('challenges'),
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
                    context.l10n.translate('viewAll'),
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
                    'title': _getLocalizedChallengeTitle('7_day_water', context),
                    'endTime': now.add(const Duration(days:7)),
                    'description': _getLocalizedChallengeDescription('7_day_water', context),
                    'icon': '💧',
                    'color': const Color(0xFF29B6F6),
                    'participants': 128,
                    'habits': [
                      {'title': context.l10n.translate('drinkWater'), 'icon': '💧', 'targetValue': 8, 'targetUnit': 'glasses', 'incrementStep': 1, 'habitType': 'build'},
                    ],
                  },
                  {
                    'id': '21_day_fitness',
                    'title': _getLocalizedChallengeTitle('21_day_fitness', context),
                    'endTime': now.add(const Duration(days: 21)),
                    'description': _getLocalizedChallengeDescription('21_day_fitness', context),
                    'icon': '🏃',
                    'color': const Color(0xFF5B6EFC),
                    'participants': 256,
                    'habits': [
                      {'title': context.l10n.translate('workout'), 'icon': '💪', 'targetValue': 20, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
                      {'title': '${context.l10n.translate('take')} 8K ${context.l10n.translate('steps')}', 'icon': '🚶', 'targetValue': 8000, 'targetUnit': 'steps', 'incrementStep': 1000, 'habitType': 'build'},
                    ],
                  },
                  {
                    'id': 'morning_routine',
                    'title': _getLocalizedChallengeTitle('morning_routine', context),
                    'endTime': now.add(const Duration(days: 14)),
                    'description': _getLocalizedChallengeDescription('morning_routine', context),
                    'icon': '🌅',
                    'color': const Color(0xFFFFA726),
                    'participants': 89,
                    'habits': [
                      {'title': context.l10n.translate('meditate'), 'icon': '🧘', 'targetValue': 10, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
                      {'title': context.l10n.translate('morningStretch'), 'icon': '🤸', 'targetValue':5, 'targetUnit': 'min', 'incrementStep': 1, 'habitType': 'build'},
                    ],
                  },
                ];
                final challenge = challenges[index];
                final endTime = challenge['endTime'] as DateTime;
                final timeLeft = endTime.difference(DateTime.now());
                final days = timeLeft.inDays;
                final hours = timeLeft.inHours.remainder(24);
                final timeLeftText = days > 0 
    ? '${days} ${context.l10n.translate('daysLeft')} ${hours}${context.l10n.translate('hoursLeft')}' 
    : '${hours} ${context.l10n.translate('hoursLeft')}';
                
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
                        // ${context.l10n.translate('timeLeft')}
                        Text(
                          timeLeftText,
                          style: AppFonts.bodyAlternative.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // ${context.l10n.translate('habitsCount')}
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
                              '${(challenge['habits'] as List<dynamic>?)?.length ?? 1} ${context.l10n.translate('habitsCount')}',
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
                  context.l10n.translate('learning'),
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
                    context.l10n.translate('viewAll'),
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
                    'title': _getLocalizedLessonTitle('water_benefits', context),
                    'subtitle': _getLocalizedLessonSubtitle('water_benefits', context),
                    'emoji': '💧',
                    'duration': '5 ${context.l10n.translate('minRead')}',
                    'difficulty': _getLocalizedLessonDifficulty('Beginner', context),
                    'color': const Color(0xFF29B6F6),
                    'readTime': 5,
                  },
                  {
                    'id': 'walking_benefits',
                    'title': _getLocalizedLessonTitle('walking_benefits', context),
                    'subtitle': _getLocalizedLessonSubtitle('walking_benefits', context),
                    'emoji': '🚶',
                    'duration': '8 ${context.l10n.translate('minRead')}',
                    'difficulty': _getLocalizedLessonDifficulty('Beginner', context),
                    'color': const Color(0xFF66BB6A),
                    'readTime': 8,
                  },
                  {
                    'id': 'morning_routine',
                    'title': _getLocalizedLessonTitle('morning_routine', context),
                    'subtitle': _getLocalizedLessonSubtitle('morning_routine', context),
                    'emoji': '🌅',
                    'duration': '12 ${context.l10n.translate('minRead')}',
                    'difficulty': _getLocalizedLessonDifficulty('Intermediate', context),
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
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                // Метаданные
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 2,
                                  alignment: WrapAlignment.start,
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
                                        softWrap: true,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      lesson['duration'] as String,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 8,
                                      ),
                                      softWrap: true,
                                      overflow: TextOverflow.ellipsis,
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
