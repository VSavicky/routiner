import 'dart:async';
import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/features/challenges/domain/services/challenges_service.dart';
import 'package:routiner/features/challenges/presentation/screens/challenges_list_screen.dart';
import 'package:routiner/features/challenges/presentation/screens/challenge_detail_screen.dart';
import 'package:routiner/l10n/app_localizations.dart';

class JoinedChallengesWidget extends StatefulWidget {
  final VoidCallback? onViewAllPressed;
  final DateTime? selectedDate; // Дата для которой показывать прогресс (null = сегодня)
  final AppLocalizations l10n;

  const JoinedChallengesWidget({
    super.key,
    this.onViewAllPressed,
    this.selectedDate,
    required this.l10n,
  });

  @override
  State<JoinedChallengesWidget> createState() => _JoinedChallengesWidgetState();
}

class _JoinedChallengesWidgetState extends State<JoinedChallengesWidget> {
  final ChallengesService _challengesService = ChallengesService();
  List<Map<String, dynamic>> _joinedChallenges = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Загружаем челленджи
    _loadJoinedChallenges();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Обновляем данные при возврате на экран
    _loadJoinedChallenges();
  }

  @override
  void didUpdateWidget(covariant JoinedChallengesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Перезагружаем челленджи если изменилась выбранная дата
    if (oldWidget.selectedDate != widget.selectedDate) {
      _loadJoinedChallenges();
    }
  }

  Future<void> _loadJoinedChallenges() async {
    // Загружаем челленджи, активные на выбранную дату
    final challenges = await _challengesService.getJoinedChallengesForDate(widget.selectedDate);
    if (mounted) {
      setState(() {
        _joinedChallenges = challenges;
        _isLoading = false;
      });
    }
  }

  String _formatTimeLeft(DateTime endTime, {DateTime? selectedDate}) {
    // Если выбрана конкретная дата (исторический просмотр)
    if (selectedDate != null) {
      final endDay = DateTime(endTime.year, endTime.month, endTime.day);
      final selectedDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      
      // Если челлендж уже завершился к выбранной дате
      if (selectedDay.isAfter(endDay)) {
        return widget.l10n.translate('ended');
      }
      
      // Показываем сколько дней осталось от выбранной даты до конца
      final daysRemaining = endDay.difference(selectedDay).inDays;
      if (daysRemaining == 0) {
        return widget.l10n.translate('lastDay');
      } else if (daysRemaining == 1) {
        return widget.l10n.translate('dayLeft');
      } else {
        return '$daysRemaining ${widget.l10n.translate('daysLeft')}';
      }
    }
    
    // Для текущей даты - стандартная логика
    final now = DateTime.now();
    final difference = endTime.difference(now);
    
    if (difference.isNegative) return widget.l10n.translate('ended');
    
    final days = difference.inDays;
    final hours = difference.inHours.remainder(24);
    
    if (days > 0) {
      return '$days ${widget.l10n.translate('daysLeft')} ${hours}h ${widget.l10n.translate('hoursLeft')}';
    } else if (hours > 0) {
      return '$hours ${widget.l10n.translate('hoursLeft')}';
    } else {
      return '${difference.inMinutes} ${widget.l10n.translate('minutesLeft')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.blue,
            ),
          ),
        ),
      );
    }

    // Если нет присоединённых челленджей, показываем заглушку
    if (_joinedChallenges.isEmpty) {
      return _buildEmptyWidget();
    }

    // Просто Column без SingleChildScrollView чтобы не мешать скроллу страницы
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.l10n.translate('challengesTitle'),
              style: AppFonts.bodyTitleMedium.copyWith(
                color: AppColors.black100,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            GestureDetector(
              onTap: widget.onViewAllPressed ?? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ChallengesListScreen(),
                  ),
                    );
                  },
                  child: Text(
                    widget.l10n.translate('viewAll'),
                    style: AppFonts.bodyTitleMedium.copyWith(
                      color: AppColors.blue100,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Список челленджей
            ..._joinedChallenges.map((challenge) => _buildChallengeCard(challenge)),
          ],
        );
  }

  Widget _buildEmptyWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.l10n.translate('challengesTitle'),
              style: AppFonts.bodyTitleMedium.copyWith(
                color: AppColors.black100,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            GestureDetector(
              onTap: widget.onViewAllPressed ?? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ChallengesListScreen(),
                  ),
                ).then((_) => _loadJoinedChallenges()); // Обновляем при возврате
              },
              child: Text(
                widget.l10n.translate('viewAll'),
                style: AppFonts.bodyTitleMedium.copyWith(
                  color: AppColors.blue100,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Карточка с призывом присоединиться
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ChallengesListScreen(),
              ),
            ).then((_) => _loadJoinedChallenges()); // Обновляем при возврате
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blue10,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.blue20,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.l10n.translate('joinChallenge'),
                        style: AppFonts.bodyTitleMedium.copyWith(
                          color: AppColors.black100,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        widget.l10n.translate('challengeDescription'),
                        style: AppFonts.bodyAlternative.copyWith(
                          color: AppColors.black40,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.blue,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getLocalizedChallengeTitle(String challengeId) {
    switch (challengeId) {
      case '7_day_water':
        return widget.l10n.translate('7DayWaterChallenge');
      case '21_day_fitness':
        return widget.l10n.translate('21DayFitnessKickstart');
      case 'morning_routine':
        return widget.l10n.translate('perfectMorningRoutine');
      case 'read_daily':
        return widget.l10n.translate('dailyReadingHabit');
      case 'eat_healthy':
        return widget.l10n.translate('healthyEatingWeek');
      case 'no_phone_before_bed':
        return widget.l10n.translate('betterSleepNoPhoneBeforeBed');
      case 'no_sugar_week':
        return widget.l10n.translate('noSugarWeek');
      case 'reduce_caffeine':
        return widget.l10n.translate('reduceCaffeineIntake');
      case 'no_procrastination':
        return widget.l10n.translate('beatProcrastination');
      case 'less_tv':
        return widget.l10n.translate('lessScreenTime');
      default:
        return challengeId;
    }
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge) {
    final String title = challenge['title'] as String? ?? 'Challenge';
    final String challengeId = challenge['id'] as String? ?? title;
    final String localizedTitle = _getLocalizedChallengeTitle(challengeId);
    final DateTime endTime = challenge['endTime'] as DateTime? ?? 
                             DateTime.now().add(const Duration(days: 7));
    final String icon = challenge['icon'] as String? ?? '🏆';
    final Color color = challenge['color'] as Color? ?? AppColors.blue;
    final int participants = challenge['participants'] as int? ?? 5;

    final String timeLeftText = _formatTimeLeft(endTime, selectedDate: widget.selectedDate);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChallengeDetailScreen(
              challenge: challenge,
              onJoinChanged: () {
                // Немедленно обновляем при изменении
                _loadJoinedChallenges();
              },
            ),
          ),
        ).then((_) => _loadJoinedChallenges()); // Обновляем при возврате
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.black10,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Иконка челленджа
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Название и время
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizedTitle,
                        style: AppFonts.bodyTitleMedium.copyWith(
                          color: AppColors.black100,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeLeftText,
                        style: AppFonts.bodyAlternative.copyWith(
                          color: AppColors.black40,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Участники
                _buildParticipantsIndicator(participants),
              ],
            ),
            const SizedBox(height: 12),
            // Прогресс бар - получаем из Firestore в реальном времени
            // Для выбранной даты (или сегодня если не указана)
            StreamBuilder<Map<String, dynamic>>(
              stream: _challengesService.getChallengeStatsStream(
                _challengesService.currentUserId ?? '',
                challengeId,
                date: widget.selectedDate,
              ),
              builder: (context, snapshot) {
                final stats = snapshot.data ?? {
                  'progress': 0.0,
                  'progressPercent': 0,
                  'completedHabits': 0,
                  'totalHabits': 0,
                };
                final progress = stats['progress'] as double;
                final progressPercent = stats['progressPercent'] as int;
                final completedHabits = stats['completedHabits'] as int;
                final totalHabits = stats['totalHabits'] as int;
                
                // Показываем индикатор загрузки если данных еще нет
                final isLoading = !snapshot.hasData && !snapshot.hasError;

                return Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.black10,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: isLoading 
                          ? null
                          : FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: progress >= 1.0 ? AppColors.green40 : color,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    isLoading
                      ? SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: color,
                          ),
                        )
                      : Text(
                          '$progressPercent%',
                          style: AppFonts.bodyAlternative.copyWith(
                            color: progress >= 1.0 ? AppColors.green40 : AppColors.black40,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    if (totalHabits > 0 && !isLoading) ...[
                      const SizedBox(width: 4),
                      Text(
                        '($completedHabits/$totalHabits)',
                        style: AppFonts.bodyAlternative.copyWith(
                          color: progress >= 1.0 ? AppColors.green40 : AppColors.black40,
                          fontSize: 10,
                        ),
                      ),
                    ],
                    // Индикатор завершения дня
                    if (progress >= 1.0 && !isLoading) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.green10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.green40,
                              size: 10,
                            ),
                            SizedBox(width: 2),
                            Text(
                              widget.l10n.translate('done'),
                              style: AppFonts.bodyAlternative.copyWith(
                                color: AppColors.green40,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsIndicator(int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.people,
          color: AppColors.black40,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: AppFonts.bodyAlternative.copyWith(
            color: AppColors.black40,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
