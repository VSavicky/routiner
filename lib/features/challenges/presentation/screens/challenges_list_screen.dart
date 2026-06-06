import 'dart:async';
import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'challenge_detail_screen.dart';
import 'package:routiner/l10n/app_localizations.dart';

class ChallengesListScreen extends StatefulWidget {
  const ChallengesListScreen({super.key});

  @override
  State<ChallengesListScreen> createState() => _ChallengesListScreenState();
}

class _ChallengesListScreenState extends State<ChallengesListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _challenges = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
    // Обновляем таймеры каждую секунду
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimeLeft(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    
    // Временно используем жестко закодированный формат для проверки
    if (days > 0) {
      return '$days дней $hoursч осталось';
    } else if (hours > 0) {
      return '$hours часа $minutesм осталось';
    } else {
      return '$minutes минут осталось';
    }
  }

  String _getLocalizedChallengeTitle(String challengeId) {
    final l10n = context.l10n;
    switch (challengeId) {
      case '7_day_water':
        return l10n.translate('7DayWaterChallenge');
      case '21_day_fitness':
        return l10n.translate('21DayFitnessKickstart');
      case 'morning_routine':
        return l10n.translate('perfectMorningRoutine');
      case 'read_daily':
        return l10n.translate('dailyReadingHabit');
      case 'eat_healthy':
        return l10n.translate('healthyEatingWeek');
      case 'no_phone_before_bed':
        return l10n.translate('betterSleepNoPhoneBeforeBed');
      case 'no_sugar_week':
        return l10n.translate('noSugarWeek');
      case 'reduce_caffeine':
        return l10n.translate('reduceCaffeineIntake');
      case 'no_procrastination':
        return l10n.translate('beatProcrastination');
      case 'less_tv':
        return l10n.translate('lessScreenTime');
      default:
        return challengeId;
    }
  }

  Future<void> _loadChallenges() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      
      final l10n = context.l10n;
      final challenges = [
        {
          'id': '7_day_water',
          'title': l10n.translate('7DayWaterChallenge'),
          'endTime': now.add(const Duration(days: 7)),
          'description': l10n.translate('7DayWaterChallengeDescription'),
          'icon': '💧',
          'color': const Color(0xFF29B6F6),
          'participants': 128,
          'habits': [
            {'title': l10n.translate('drinkWaterHabit'), 'icon': '💧', 'targetValue': 8, 'targetUnit': 'glasses', 'incrementStep': 1, 'habitType': 'build'},
          ],
        },
        {
          'id': '21_day_fitness',
          'title': l10n.translate('21DayFitnessKickstart'),
          'endTime': now.add(const Duration(days: 21)),
          'description': l10n.translate('21DayFitnessKickstartDescription'),
          'icon': '🏃',
          'color': const Color(0xFF5B6EFC),
          'participants': 256,
          'habits': [
            {'title': l10n.translate('dailyWorkoutHabit'), 'icon': '💪', 'targetValue': 20, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
            {'title': l10n.translate('take8KStepsHabit'), 'icon': '🚶', 'targetValue': 8000, 'targetUnit': 'steps', 'incrementStep': 1000, 'habitType': 'build'},
          ],
        },
        {
          'id': 'morning_routine',
          'title': l10n.translate('perfectMorningRoutine'),
          'endTime': now.add(const Duration(days: 14)),
          'description': l10n.translate('perfectMorningRoutineDescription'),
          'icon': '🌅',
          'color': const Color(0xFFFFA726),
          'participants': 89,
          'habits': [
            {'title': l10n.translate('meditateHabit'), 'icon': '🧘', 'targetValue': 10, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
            {'title': l10n.translate('morningStretchHabit'), 'icon': '🤸', 'targetValue': 5, 'targetUnit': 'min', 'incrementStep': 1, 'habitType': 'build'},
          ],
        },
        {
          'id': 'read_daily',
          'title': l10n.translate('dailyReadingHabit'),
          'endTime': now.add(const Duration(days: 30)),
          'description': l10n.translate('dailyReadingHabitDescription'),
          'icon': '📚',
          'color': const Color(0xFF8D6E63),
          'participants': 167,
          'habits': [
            {'title': l10n.translate('readBookHabit'), 'icon': '📖', 'targetValue': 20, 'targetUnit': 'pages', 'incrementStep': 5, 'habitType': 'build'},
          ],
        },
        {
          'id': 'eat_healthy',
          'title': l10n.translate('healthyEatingWeek'),
          'endTime': now.add(const Duration(days: 7)),
          'description': l10n.translate('healthyEatingWeekDescription'),
          'icon': '🥗',
          'color': const Color(0xFF66BB6A),
          'participants': 203,
          'habits': [
            {'title': l10n.translate('eatVegetablesHabit'), 'icon': '🥦', 'targetValue': 2, 'targetUnit': 'servings', 'incrementStep': 1, 'habitType': 'build'},
            {'title': l10n.translate('cookAtHomeHabit'), 'icon': '🍳', 'targetValue': 1, 'targetUnit': 'meal', 'incrementStep': 1, 'habitType': 'build'},
          ],
        },
        {
          'id': 'no_phone_before_bed',
          'title': l10n.translate('betterSleepNoPhoneBeforeBed'),
          'endTime': now.add(const Duration(days: 14)),
          'description': l10n.translate('betterSleepNoPhoneBeforeBedDescription'),
          'icon': '😴',
          'color': const Color(0xFF7E57C2),
          'participants': 342,
          'habits': [
            {'title': l10n.translate('noPhone1hBeforeBedHabit'), 'icon': '📵', 'targetValue': 1, 'targetUnit': 'day', 'incrementStep': 1, 'habitType': 'quit'},
            {'title': l10n.translate('readInsteadHabit'), 'icon': '📖', 'targetValue': 15, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
          ],
        },
        {
          'id': 'no_sugar_week',
          'title': l10n.translate('noSugarWeek'),
          'endTime': now.add(const Duration(days: 7)),
          'description': l10n.translate('noSugarWeekDescription'),
          'icon': '🚫',
          'color': const Color(0xFFE91E63),
          'participants': 189,
          'habits': [
            {'title': l10n.translate('noSugarHabit'), 'icon': '🍰', 'targetValue': 1, 'targetUnit': 'day', 'incrementStep': 1, 'habitType': 'quit'},
            {'title': l10n.translate('drinkWaterHabit'), 'icon': '💧', 'targetValue': 6, 'targetUnit': 'glasses', 'incrementStep': 1, 'habitType': 'build'},
          ],
        },
        {
          'id': 'reduce_caffeine',
          'title': l10n.translate('reduceCaffeineIntake'),
          'endTime': now.add(const Duration(days: 21)),
          'description': l10n.translate('reduceCaffeineIntakeDescription'),
          'icon': '☕',
          'color': const Color(0xFF795548),
          'participants': 76,
          'habits': [
            {'title': l10n.translate('max1CoffeeHabit'), 'icon': '☕', 'targetValue': 1, 'targetUnit': 'cup', 'incrementStep': 1, 'habitType': 'quit'},
            {'title': l10n.translate('drinkHerbalTeaHabit'), 'icon': '🍵', 'targetValue': 2, 'targetUnit': 'cups', 'incrementStep': 1, 'habitType': 'build'},
          ],
        },
        {
          'id': 'no_procrastination',
          'title': l10n.translate('beatProcrastination'),
          'endTime': now.add(const Duration(days: 14)),
          'description': l10n.translate('beatProcrastinationDescription'),
          'icon': '🎯',
          'color': const Color(0xFF009688),
          'participants': 134,
          'habits': [
            {'title': l10n.translate('complete3PrioritiesHabit'), 'icon': '✅', 'targetValue': 3, 'targetUnit': 'tasks', 'incrementStep': 1, 'habitType': 'build'},
            {'title': l10n.translate('noSocialMediaAtWorkHabit'), 'icon': '📱', 'targetValue': 1, 'targetUnit': 'day', 'incrementStep': 1, 'habitType': 'quit'},
          ],
        },
        {
          'id': 'less_tv',
          'title': l10n.translate('lessScreenTime'),
          'endTime': now.add(const Duration(days: 14)),
          'description': l10n.translate('lessScreenTimeDescription'),
          'icon': '📺',
          'color': const Color(0xFF607D8B),
          'participants': 98,
          'habits': [
            {'title': l10n.translate('max1hTvNetflixHabit'), 'icon': '📺', 'targetValue': 1, 'targetUnit': 'hour', 'incrementStep': 1, 'habitType': 'quit'},
            {'title': l10n.translate('goForAWalkHabit'), 'icon': '🚶', 'targetValue': 20, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
          ],
        },
      ];

      setState(() {
        _challenges = challenges;
      });
    } catch (e) {
      print('[CHALLENGES ERROR] Failed to load challenges: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onChallengeTap(Map<String, dynamic> challenge) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChallengeDetailScreen(
          challenge: challenge,
          onJoinChanged: () {
            // Callback при изменении состояния присоединения
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header как в ExploreScreen - белый фон включая статус бар
          Container(
            width: double.infinity,
            color: Colors.white,
            child: SafeArea(
              bottom: false, // Не применять SafeArea к низу, только к верху
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.black10, width: 2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: AppColors.black40,
                              size: 20,
                            ),
                          ),
                        ),
                        Text(
                          context.l10n.translate('challengesTitle'),
                          style: AppFonts.headlineH5,
                        ),
                        const SizedBox(width: 48), // Для баланса
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadChallenges,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _challenges.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: _challenges.length,
                            itemBuilder: (context, index) {
                              return _buildChallengeCard(_challenges[index]);
                            },
                          ),
              ),
            ),
               ],
        ),
      );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🏆',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.translate('noChallengesYet'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.translate('joinOrCreateChallenge'),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue100,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              context.l10n.translate('createChallenge'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge) {
    final color = challenge['color'] as Color;
    final habits = challenge['habits'] as List<dynamic>? ?? [];
    final endTime = challenge['endTime'] as DateTime;
    final timeLeft = endTime.difference(DateTime.now());
    final timeLeftText = timeLeft.isNegative ? context.l10n.translate('ended') : _formatTimeLeft(timeLeft);

    return GestureDetector(
      onTap: () => _onChallengeTap(challenge),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and title row
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        challenge['icon'] as String,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getLocalizedChallengeTitle(challenge['id'] as String),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Живой таймер!
                        Text(
                          timeLeftText,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                    context.l10n.translate('habitsCount').replaceAll('{count}', habits.length.toString()),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  // Показываем типы привычек (build/quit)
                  if (habits.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    ...habits.take(3).map((h) {
                      final habitType = (h as Map<String, dynamic>)['habitType'] as String? ?? 'build';
                      return Container(
                        margin: EdgeInsets.only(right: 4),
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: habitType == 'quit' 
                              ? Colors.red.withOpacity(0.3) 
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          habitType == 'quit' ? '🔴' : '🟢',
                          style: TextStyle(fontSize: 10),
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
