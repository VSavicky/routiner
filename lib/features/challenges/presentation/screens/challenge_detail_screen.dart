import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import '../../domain/services/challenges_service.dart';
import '../widgets/challenge_habits_widget.dart';
import '../widgets/challenge_days_list.dart';
import 'package:routiner/l10n/app_localizations.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> challenge;
  final VoidCallback? onJoinChanged;

  const ChallengeDetailScreen({
    super.key,
    required this.challenge,
    this.onJoinChanged,
  });

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  bool _isJoined = false;
  bool _isLoading = true;
  final ChallengesService _challengesService = ChallengesService();
  
  // Выбранная дата для просмотра прогресса (null = сегодня)
  DateTime? _selectedDate;
  
  // Прогресс по дням челленджа (ключ: номер дня, значение: прогресс 0.0-1.0)
  Map<int, double> _dailyProgress = {};
  
  /// Получить номер текущего дня челленджа (1-based)
  int _getCurrentDayNumber() {
    final now = DateTime.now();
    
    // Если есть выбранная дата, считаем относительно неё
    final targetDate = _selectedDate ?? now;
    final targetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
    
    // Получаем дату начала челленджа
    final startDateRaw = widget.challenge['startDate'];
    final joinedAtRaw = widget.challenge['joinedAt'];
    
    DateTime? startDate;
    if (startDateRaw is String) {
      startDate = DateTime.tryParse(startDateRaw);
    } else if (startDateRaw is DateTime) {
      startDate = startDateRaw;
    } else if (joinedAtRaw is String) {
      startDate = DateTime.tryParse(joinedAtRaw);
    } else if (joinedAtRaw is DateTime) {
      startDate = joinedAtRaw;
    }
    
    if (startDate == null) return 1; // По умолчанию первый день
    
    final startDay = DateTime(startDate.year, startDate.month, startDate.day);
    final difference = targetDay.difference(startDay).inDays;
    
    return difference >= 0 ? difference + 1 : 1;
  }
  
  /// Получить общую длительность челленджа в днях
  int _getTotalDays() {
    final endDateRaw = widget.challenge['endDate'];
    final endTimeRaw = widget.challenge['endTime'];
    final startDateRaw = widget.challenge['startDate'];
    final joinedAtRaw = widget.challenge['joinedAt'];
    
    DateTime? endDate;
    if (endDateRaw is String) {
      endDate = DateTime.tryParse(endDateRaw);
    } else if (endDateRaw is DateTime) {
      endDate = endDateRaw;
    } else if (endTimeRaw is String) {
      endDate = DateTime.tryParse(endTimeRaw);
    } else if (endTimeRaw is DateTime) {
      endDate = endTimeRaw;
    }
    
    DateTime? startDate;
    if (startDateRaw is String) {
      startDate = DateTime.tryParse(startDateRaw);
    } else if (startDateRaw is DateTime) {
      startDate = startDateRaw;
    } else if (joinedAtRaw is String) {
      startDate = DateTime.tryParse(joinedAtRaw);
    } else if (joinedAtRaw is DateTime) {
      startDate = joinedAtRaw;
    }
    
    if (endDate != null && startDate != null) {
      return endDate.difference(startDate).inDays + 1;
    }
    
    // По умолчанию 7 дней
    return 7;
  }

  @override
  void initState() {
    super.initState();
    _checkJoinedStatus();
  }
  
  /// Загрузить прогресс по дням челленджа
  Future<void> _loadDailyProgress() async {
    final userId = _challengesService.currentUserId;
    if (userId == null) return;
    
    final challengeId = widget.challenge['id'] as String? ?? widget.challenge['title'] as String;
    final totalDays = _getTotalDays();
    
    // Получаем дату начала
    final startDateRaw = widget.challenge['startDate'];
    final joinedAtRaw = widget.challenge['joinedAt'];
    
    DateTime? startDate;
    if (startDateRaw is String) {
      startDate = DateTime.tryParse(startDateRaw);
    } else if (startDateRaw is DateTime) {
      startDate = startDateRaw;
    } else if (joinedAtRaw is String) {
      startDate = DateTime.tryParse(joinedAtRaw);
    } else if (joinedAtRaw is DateTime) {
      startDate = joinedAtRaw;
    }
    
    startDate ??= DateTime.now();
    
    // Создаем список futures для параллельной загрузки
    final futures = <Future<MapEntry<int, double>>>[];
    
    for (int day = 1; day <= totalDays; day++) {
      final date = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      ).add(Duration(days: day - 1));
      
      // Добавляем future в список для параллельного выполнения
      futures.add(
        _challengesService.getChallengeStatsStream(userId, challengeId, date: date)
            .first
            .then((stats) => MapEntry(day, stats['progress'] as double? ?? 0.0))
            .catchError((_) => MapEntry(day, 0.0)),
      );
    }
    
    // Ждем завершения всех запросов параллельно
    final results = await Future.wait(futures);
    final progress = Map<int, double>.fromEntries(results);
    
    if (mounted) {
      setState(() {
        _dailyProgress = progress;
      });
    }
  }
  

  Future<void> _checkJoinedStatus() async {
    final String challengeId = widget.challenge['id'] as String? ?? 
                               widget.challenge['title'] as String;
    final bool joined = await _challengesService.isJoined(challengeId);
    if (mounted) {
      setState(() {
        _isJoined = joined;
        _isLoading = false;
      });
      // Загружаем прогресс если присоединился
      if (joined) {
        _loadDailyProgress();
      }
    }
  }

  Future<void> _toggleJoin() async {
    final String challengeId = widget.challenge['id'] as String? ?? 
                              widget.challenge['title'] as String;
    
    if (_isJoined) {
      await _challengesService.leaveChallenge(challengeId);
      if (mounted) {
        setState(() {
          _isJoined = false;
        });
      }
    } else {
      await _challengesService.joinChallenge(widget.challenge);
      if (mounted) {
        setState(() {
          _isJoined = true;
        });
        // Загружаем прогресс после присоединения
        _loadDailyProgress();
      }
    }
    
    // Уведомляем о изменении
    if (mounted) {
      widget.onJoinChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final habits = widget.challenge['habits'] as List<dynamic>? ?? [];
    final endTime = widget.challenge['endTime'] as DateTime?;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.purple,
              AppColors.blue,
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                // Header - теперь прокручивается с контентом
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  child: Row(
                    children: [
                      // Back button
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: AppColors.purple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                      
                      // Challenge icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            widget.challenge['icon'] as String,
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Title
                      Text(
                        _getLocalizedChallengeTitle(widget.challenge['id'] as String? ?? ''),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Duration and Time left
                      if (endTime != null)
                        Column(
                          children: [
                            // Оставшееся время
                            Text(
                              _formatTimeLeft(endTime.difference(DateTime.now())),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Общая продолжительность
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _calculateDuration(endTime),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      
                                            
                      const SizedBox(height: 24),
                      
                      // Description
                      Text(
                        _getLocalizedChallengeDescription(widget.challenge['id'] as String? ?? ''),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Join button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _toggleJoin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.purple,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            _isJoined ? context.l10n.translate('leaveTheChallenge') : context.l10n.translate('joinTheChallenge'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Days of challenge (Day 1, Day 2, Day 3...) - только если присоединился
                      if (_isJoined)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.translate('progressByDay'),
                              style: AppFonts.bodyAlternative.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ChallengeDaysList(
                              totalDays: _getTotalDays(),
                              selectedDay: _getCurrentDayNumber(),
                              dailyProgress: _dailyProgress,
                              onDaySelected: (dayNumber) {
                                // Вычисляем дату для выбранного дня челленджа
                                final startDateRaw = widget.challenge['startDate'];
                                final joinedAtRaw = widget.challenge['joinedAt'];
                                
                                DateTime? startDate;
                                if (startDateRaw is String) {
                                  startDate = DateTime.tryParse(startDateRaw);
                                } else if (startDateRaw is DateTime) {
                                  startDate = startDateRaw;
                                } else if (joinedAtRaw is String) {
                                  startDate = DateTime.tryParse(joinedAtRaw);
                                } else if (joinedAtRaw is DateTime) {
                                  startDate = joinedAtRaw;
                                }
                                
                                startDate ??= DateTime.now();
                                final selectedDate = DateTime(
                                  startDate.year,
                                  startDate.month,
                                  startDate.day,
                                ).add(Duration(days: dayNumber - 1));
                                
                                setState(() {
                                  _selectedDate = selectedDate;
                                });
                              },
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      
                      // Challenge habits list
                      if (_isJoined)
                        ChallengeHabitsWidget(
                          key: ValueKey('challenge_habits_${_isJoined}_${_selectedDate?.toIso8601String()}'),
                          challengeId: widget.challenge['id'] as String? ?? widget.challenge['title'] as String,
                          challengeColor: AppColors.purple,
                          selectedDate: _selectedDate,
                          l10n: context.l10n,
                          onProgressChanged: () {
                            // Перезагружаем прогресс по дням при изменении привычки
                            _loadDailyProgress();
                          },
                        )
                      else
                        // Preview of challenge habits (before joining)
                        for (int i = 0; i < habits.length; i++)
                          _buildHabitCard(habits[i] as Map<String, dynamic>, AppColors.purple),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

  String _formatTimeLeft(Duration duration) {
    if (duration.isNegative) return context.l10n.translate('ended');
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    
    if (days > 0) return '$days дней $hoursч осталось';
    if (hours > 0) return '$hours часа $minutesм осталось';
    return '$minutes минут осталось';
  }

  String _getLocalizedChallengeTitle(String challengeId) {
    switch (challengeId) {
      case '7_day_water':
        return context.l10n.translate('sevenDayWaterChallenge');
      case '21_day_fitness':
        return context.l10n.translate('twentyOneDayFitnessKickstart');
      case 'morning_routine':
        return context.l10n.translate('perfectMorningRoutine');
      case 'read_daily':
        return context.l10n.translate('dailyReadingHabit');
      case 'eat_healthy':
        return context.l10n.translate('healthyEatingWeek');
      case 'no_phone_before_bed':
        return context.l10n.translate('betterSleepNoPhoneBeforeBed');
      case 'no_sugar_week':
        return context.l10n.translate('noSugarWeek');
      case 'reduce_caffeine':
        return context.l10n.translate('reduceCaffeineIntake');
      case 'no_procrastination':
        return context.l10n.translate('beatProcrastination');
      case 'less_tv':
        return context.l10n.translate('lessScreenTime');
      default:
        return challengeId;
    }
  }

  String _getLocalizedChallengeDescription(String challengeId) {
    switch (challengeId) {
      case '7_day_water':
        return context.l10n.translate('sevenDayWaterChallengeDescription');
      case '21_day_fitness':
        return context.l10n.translate('twentyOneDayFitnessKickstartDescription');
      case 'morning_routine':
        return context.l10n.translate('perfectMorningRoutineDescription');
      case 'read_daily':
        return context.l10n.translate('dailyReadingHabitDescription');
      case 'eat_healthy':
        return context.l10n.translate('healthyEatingWeekDescription');
      case 'no_phone_before_bed':
        return context.l10n.translate('betterSleepNoPhoneBeforeBedDescription');
      case 'no_sugar_week':
        return context.l10n.translate('noSugarWeekDescription');
      case 'reduce_caffeine':
        return context.l10n.translate('reduceCaffeineIntakeDescription');
      case 'no_procrastination':
        return context.l10n.translate('beatProcrastinationDescription');
      case 'less_tv':
        return context.l10n.translate('lessScreenTimeDescription');
      default:
        return widget.challenge['description'] as String? ?? '';
    }
  }

  String _getLocalizedHabitTitle(String habitTitle) {
    switch (habitTitle) {
      case 'Drink water':
        return context.l10n.translate('drinkWater');
      case 'Daily workout':
        return context.l10n.translate('dailyWorkout');
      case 'Take 8K steps':
        return context.l10n.translate('take8KSteps');
      case 'Meditate':
        return context.l10n.translate('meditate');
      case 'Morning stretch':
        return context.l10n.translate('morningStretch');
      case 'Read book':
        return context.l10n.translate('readBook');
      case 'Eat vegetables':
        return context.l10n.translate('eatVegetables');
      case 'Cook at home':
        return context.l10n.translate('cookAtHome');
      case 'No phone 1h before bed':
        return context.l10n.translate('noPhone1hBeforeBed');
      case 'Read instead':
        return context.l10n.translate('readInstead');
      case 'No sugar':
        return context.l10n.translate('noSugar');
      case 'Max 1 coffee':
        return context.l10n.translate('max1Coffee');
      case 'Drink herbal tea':
        return context.l10n.translate('drinkHerbalTea');
      case 'Complete 3 priorities':
        return context.l10n.translate('complete3Priorities');
      case 'No social media at work':
        return context.l10n.translate('noSocialMediaAtWork');
      case 'Max 1h TV/Netflix':
        return context.l10n.translate('max1hTvNetflix');
      case 'Go for a walk':
        return context.l10n.translate('goForAWalk');
      default:
        return habitTitle;
    }
  }

  String _getLocalizedUnit(String unit) {
    switch (unit) {
      case 'glasses':
        return context.l10n.translate('glasses');
      case 'min':
        return context.l10n.translate('min');
      case 'steps':
        return context.l10n.translate('steps');
      case 'servings':
        return context.l10n.translate('servings');
      case 'meal':
        return context.l10n.translate('meal');
      case 'day':
        return context.l10n.translate('day');
      case 'pages':
        return context.l10n.translate('pages');
      case 'cups':
        return context.l10n.translate('cups');
      case 'tasks':
        return context.l10n.translate('tasks');
      case 'hour':
        return context.l10n.translate('hour');
      default:
        return unit;
    }
  }

  String _calculateDuration(DateTime endTime) {
    // Рассчитываем разницу между сейчас и endTime
    final now = DateTime.now();
    final difference = endTime.difference(now);
    
    // Если челлендж уже начат, считаем от даты начала (предполагаем что челлендж начался вчера или сегодня)
    // В реальном приложении нужно сохранять дату начала челленджа
    // Здесь приближенно считаем по endTime
    
    // Для простоты выводим примерную продолжительность в днях
    final days = difference.inDays.abs();
    
    if (days == 7) return context.l10n.translate('7DayChallenge');
    if (days == 14) return context.l10n.translate('14DayChallenge');
    if (days == 21) return context.l10n.translate('21DayChallenge');
    if (days == 30) return context.l10n.translate('30DayChallenge');
    if (days < 7) return context.l10n.translate('dayChallenge').replaceAll('{days}', days.toString());
    if (days < 30) return context.l10n.translate('weekChallenge').replaceAll('{weeks}', (days / 7).round().toString());
    return context.l10n.translate('monthChallenge').replaceAll('{months}', (days / 30).round().toString());
  }

  Widget _buildHabitCard(Map<String, dynamic> habit, Color challengeColor) {
    final targetValue = habit['targetValue'] as int? ?? 1;
    final targetUnit = habit['targetUnit'] as String? ?? 'times';
    final habitType = habit['habitType'] as String? ?? 'build';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Row(
        children: [
          // Habit icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: challengeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                habit['icon'] as String? ?? '📝',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Habit info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getLocalizedHabitTitle(habit['title'] as String? ?? 'Habit'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: habitType == 'quit' ? Colors.red.withOpacity(0.1) : challengeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        habitType == 'quit' ? context.l10n.translate('quit') : context.l10n.translate('build'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: habitType == 'quit' ? Colors.red : challengeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$targetValue ${_getLocalizedUnit(targetUnit)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
                  ],
      ),
    );
  }
}
