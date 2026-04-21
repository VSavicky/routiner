import 'dart:async';
import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'challenge_detail_screen.dart';

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
    
    if (days > 0) {
      return '$days days ${hours}h left';
    } else if (hours > 0) {
      return '$hours hours ${minutes}m left';
    } else {
      return '$minutes minutes left';
    }
  }

  Future<void> _loadChallenges() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      
      final challenges = [
        {
          'id': '1',
          'title': 'Best Runners!',
          'endTime': now.add(const Duration(days: 5, hours: 13, minutes: 45)),
          'description': 'Join our weekly running challenge and compete with friends! Track your progress and earn rewards.',
          'icon': '🏃',
          'color': const Color(0xFF5B6EFC),
          'participants': 12,
          'tasks': [
            {'name': 'Drink the water', 'progress': '500/2000 ML', 'icon': '💧'},
            {'name': 'Walk', 'progress': '0/10000 STEPS', 'icon': '🚶'},
            {'name': 'Water Plants', 'progress': '0/1 TIMES', 'icon': '🌱'},
            {'name': 'Meditate', 'progress': '20/20 MIN', 'icon': '🧘'},
          ],
        },
        {
          'id': '2',
          'title': 'Morning Routine',
          'endTime': now.add(const Duration(days: 3, hours: 8, minutes: 30)),
          'description': 'Build a perfect morning routine with meditation, exercise and healthy breakfast.',
          'icon': '🌅',
          'color': const Color(0xFFFFA726),
          'participants': 8,
          'tasks': [
            {'name': 'Meditate', 'progress': '10/15 MIN', 'icon': '🧘'},
            {'name': 'Stretch', 'progress': '5/10 MIN', 'icon': '🤸'},
            {'name': 'Read Book', 'progress': '0/20 PAGES', 'icon': '📚'},
          ],
        },
        {
          'id': '3',
          'title': 'Hydration Master',
          'endTime': now.add(const Duration(days: 12, hours: 6, minutes: 15)),
          'description': 'Stay hydrated! Drink 2 liters of water every day for the challenge period.',
          'icon': '💧',
          'color': const Color(0xFF29B6F6),
          'participants': 24,
          'tasks': [
            {'name': 'Drink water', 'progress': '1500/2000 ML', 'icon': '💧'},
            {'name': 'Track intake', 'progress': '3/8 times', 'icon': '📝'},
          ],
        },
        {
          'id': '4',
          'title': 'Sleep Better',
          'endTime': now.add(const Duration(days: 7, hours: 22, minutes: 10)),
          'description': 'Improve your sleep quality with consistent bedtime routine and no screens before bed.',
          'icon': '😴',
          'color': const Color(0xFF7E57C2),
          'participants': 15,
          'tasks': [
            {'name': 'No phones', 'progress': '5/7 days', 'icon': '📵'},
            {'name': 'Sleep by 11pm', 'progress': '3/7 days', 'icon': '🌙'},
            {'name': 'Read before bed', 'progress': '6/7 days', 'icon': '📖'},
          ],
        },
        {
          'id': '5',
          'title': 'Healthy Eating',
          'endTime': now.add(const Duration(days: 14, hours: 5, minutes: 55)),
          'description': 'Eat healthy meals, avoid junk food and track your nutrition for two weeks.',
          'icon': '🥗',
          'color': const Color(0xFF66BB6A),
          'participants': 31,
          'tasks': [
            {'name': 'Eat vegetables', 'progress': '2/3 meals', 'icon': '🥦'},
            {'name': 'No sugar', 'progress': '4/7 days', 'icon': '🚫'},
            {'name': 'Cook at home', 'progress': '5/7 meals', 'icon': '👨‍🍳'},
            {'name': 'Track calories', 'progress': '1200/2000', 'icon': '📊'},
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
                          'Challenges',
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
          const Text(
            'No challenges yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Join or create a challenge to get started!',
            style: TextStyle(
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
            child: const Text(
              'Create Challenge',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge) {
    final color = challenge['color'] as Color;
    final participants = challenge['participants'] as int;
    final tasks = challenge['tasks'] as List<dynamic>;
    final endTime = challenge['endTime'] as DateTime;
    final timeLeft = endTime.difference(DateTime.now());
    final timeLeftText = timeLeft.isNegative ? 'Ended' : _formatTimeLeft(timeLeft);

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
                          challenge['title'] as String,
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
              // Participants avatars - ФИКС: увеличил ширину Stack
              Row(
                children: [
                  SizedBox(
                    width: 130, // Увеличили с 100 до 130
                    height: 44,
                    child: Stack(
                      children: [
                        for (int i = 0; i < 3 && i < participants; i++)
                          Positioned(
                            left: i * 16.0, // Намного ближе друг к другу (наезд)
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: color,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  'https://i.pravatar.cc/150?img=${10 + i}',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: Icon(
                                        Icons.person,
                                        size: 18,
                                        color: Colors.grey[600],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        if (participants > 3)
                          Positioned(
                            left: 48, // Корректируем позицию бейджа
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: color,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '+${participants - 3}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: color,
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
              const SizedBox(height: 12),
              // Tasks count
              Text(
                '${tasks.length} tasks',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
