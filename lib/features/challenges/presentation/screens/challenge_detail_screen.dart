import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import '../../domain/services/challenges_service.dart';
import '../widgets/challenge_habits_widget.dart';
import '../widgets/challenge_days_list.dart';

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
    final participants = widget.challenge['participants'] as int;
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
                        widget.challenge['title'] as String,
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
                      
                      // Participants avatars - наезжают друг на друга (по центру)
                      Center(
                        child: SizedBox(
                          width: 160,
                          height: 52,
                          child: Stack(
                            children: [
                              for (int i = 0; i < 4 && i < participants; i++)
                                Positioned(
                                  left: i * 20.0, // Намного ближе друг к другу (наезд)
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: AppColors.purple,
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Image.network(
                                        'https://i.pravatar.cc/150?img=${10 + i}',
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[300],
                                            child: Icon(
                                              Icons.person,
                                              size: 22,
                                              color: Colors.grey[600],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                            if (participants > 4)
                              Positioned(
                                left: 80, // Корректируем позицию бейджа
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: AppColors.purple,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '+${participants - 4}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.purple,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Description
                      Text(
                        widget.challenge['description'] as String,
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
                            _isJoined ? 'Leave the Challenge' : 'Join the Challenge',
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
                              'Progress by Day',
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
    if (duration.isNegative) return 'Ended';
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    
    if (days > 0) return '$days days ${hours}h left';
    if (hours > 0) return '$hours hours ${minutes}m left';
    return '$minutes minutes left';
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
    
    if (days == 7) return '7-Day Challenge';
    if (days == 14) return '14-Day Challenge';
    if (days == 21) return '21-Day Challenge';
    if (days == 30) return '30-Day Challenge';
    if (days < 7) return '$days-Day Challenge';
    if (days < 30) return '${(days / 7).round()}-Week Challenge';
    return '${(days / 30).round()}-Month Challenge';
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
                  habit['title'] as String? ?? 'Habit',
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
                        habitType == 'quit' ? 'QUIT' : 'BUILD',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: habitType == 'quit' ? Colors.red : challengeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$targetValue $targetUnit',
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
          // Participants mini avatars - ФИКС
          SizedBox(
            width: 70,
            height: 32,
            child: Stack(
              children: [
                for (int i = 0; i < 2; i++)
                  Positioned(
                    right: i * 18.0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          'https://i.pravatar.cc/150?img=${20 + i}',
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey[600],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 36,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '+3',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.purple,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
