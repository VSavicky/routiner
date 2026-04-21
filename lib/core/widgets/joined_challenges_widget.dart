import 'dart:async';
import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/features/challenges/domain/services/challenges_service.dart';
import 'package:routiner/features/challenges/presentation/screens/challenges_list_screen.dart';
import 'package:routiner/features/challenges/presentation/screens/challenge_detail_screen.dart';

class JoinedChallengesWidget extends StatefulWidget {
  final VoidCallback? onViewAllPressed;

  const JoinedChallengesWidget({
    super.key,
    this.onViewAllPressed,
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
    // Обновляем каждую минуту для обновления прогресса
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
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

  Future<void> _loadJoinedChallenges() async {
    final challenges = await _challengesService.getJoinedChallenges();
    if (mounted) {
      setState(() {
        _joinedChallenges = challenges;
        _isLoading = false;
      });
    }
  }

  String _formatTimeLeft(DateTime endTime) {
    final now = DateTime.now();
    final difference = endTime.difference(now);
    
    if (difference.isNegative) return 'Ended';
    
    final days = difference.inDays;
    final hours = difference.inHours.remainder(24);
    
    if (days > 0) {
      return '$days days ${hours}h left';
    } else if (hours > 0) {
      return '$hours hours left';
    } else {
      return '${difference.inMinutes} min left';
    }
  }

  double _calculateProgress(DateTime startTime, DateTime endTime) {
    final now = DateTime.now();
    final total = endTime.difference(startTime).inSeconds;
    final remaining = endTime.difference(now).inSeconds;
    
    if (remaining <= 0) return 0;
    if (remaining >= total) return 1;
    
    return remaining / total;
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
              'Challenges',
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
                    'VIEW ALL',
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
              'Challenges',
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
                'VIEW ALL',
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
                        'Join a Challenge!',
                        style: AppFonts.bodyTitleMedium.copyWith(
                          color: AppColors.black100,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Compete with friends and track your progress',
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

  Widget _buildChallengeCard(Map<String, dynamic> challenge) {
    final String title = challenge['title'] as String? ?? 'Challenge';
    final DateTime endTime = challenge['endTime'] as DateTime? ?? 
                             DateTime.now().add(const Duration(days: 7));
    final DateTime startTime = challenge['joinedAt'] != null 
        ? (challenge['joinedAt'] is DateTime 
            ? challenge['joinedAt'] as DateTime
            : DateTime.parse(challenge['joinedAt'] as String))
        : DateTime.now().subtract(const Duration(days: 2));
    final String icon = challenge['icon'] as String? ?? '🏆';
    final Color color = challenge['color'] as Color? ?? AppColors.blue;
    final int participants = challenge['participants'] as int? ?? 5;

    final String timeLeftText = _formatTimeLeft(endTime);
    final double progress = _calculateProgress(startTime, endTime);
    final int progressPercent = (progress * 100).round();

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
                        title,
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
            // Прогресс бар
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.black10,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$progressPercent%',
                  style: AppFonts.bodyAlternative.copyWith(
                    color: AppColors.black40,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
