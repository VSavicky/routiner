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
        // ========== ЧЕЛЛЕНДЖИ ДЛЯ ХОРОШИХ ПРИВЫЧЕК (build) ==========
        {
          'id': '7_day_water',
          'title': '7-Day Water Challenge',
          'endTime': now.add(const Duration(days: 7)),
          'description': 'Start your wellness journey with proper hydration. Drink 8 glasses of water daily for one week and feel the difference in your energy levels and skin health.',
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
          'description': 'Build a consistent workout habit in just 3 weeks. Start with manageable 20-minute sessions and transform your fitness level. Perfect for beginners!',
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
          'description': 'Transform your mornings and set the tone for productive days. Simple 10-minute meditation and light stretching to wake up your body and mind.',
          'icon': '🌅',
          'color': const Color(0xFFFFA726),
          'participants': 89,
          'habits': [
            {'title': 'Meditate', 'icon': '🧘', 'targetValue': 10, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
            {'title': 'Morning stretch', 'icon': '🤸', 'targetValue': 5, 'targetUnit': 'min', 'incrementStep': 1, 'habitType': 'build'},
          ],
        },
        {
          'id': 'read_daily',
          'title': 'Daily Reading Habit',
          'endTime': now.add(const Duration(days: 30)),
          'description': 'Read 20 pages every day for a month and finish that book you have been meaning to read. Expand your knowledge and reduce screen time before bed.',
          'icon': '📚',
          'color': const Color(0xFF8D6E63),
          'participants': 167,
          'habits': [
            {'title': 'Read book', 'icon': '📖', 'targetValue': 20, 'targetUnit': 'pages', 'incrementStep': 5, 'habitType': 'build'},
          ],
        },
        {
          'id': 'eat_healthy',
          'title': 'Healthy Eating Week',
          'endTime': now.add(const Duration(days: 7)),
          'description': 'One week of nutritious meals! Focus on vegetables, home cooking, and cutting out processed foods. Small changes that make a big difference.',
          'icon': '🥗',
          'color': const Color(0xFF66BB6A),
          'participants': 203,
          'habits': [
            {'title': 'Eat vegetables', 'icon': '🥦', 'targetValue': 2, 'targetUnit': 'servings', 'incrementStep': 1, 'habitType': 'build'},
            {'title': 'Cook at home', 'icon': '🍳', 'targetValue': 1, 'targetUnit': 'meal', 'incrementStep': 1, 'habitType': 'build'},
          ],
        },
        // ========== ЧЕЛЛЕНДЖИ ДЛЯ ПЛОХИХ ПРИВЫЧЕК (quit) ==========
        {
          'id': 'no_phone_before_bed',
          'title': 'Better Sleep: No Phone Before Bed',
          'endTime': now.add(const Duration(days: 14)),
          'description': 'Improve your sleep quality by eliminating screen time 1 hour before bed. Fall asleep faster and wake up more refreshed. Your eyes will thank you!',
          'icon': '�',
          'color': const Color(0xFF7E57C2),
          'participants': 342,
          'habits': [
            {'title': 'No phone 1h before bed', 'icon': '📵', 'targetValue': 1, 'targetUnit': 'day', 'incrementStep': 1, 'habitType': 'quit'},
            {'title': 'Read instead', 'icon': '�', 'targetValue': 15, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
          ],
        },
        {
          'id': 'no_sugar_week',
          'title': 'No Sugar Week',
          'endTime': now.add(const Duration(days: 7)),
          'description': 'Challenge yourself to one week without added sugars. No desserts, no sodas, no sweet snacks. Break the sugar addiction and discover natural flavors!',
          'icon': '🚫',
          'color': const Color(0xFFE91E63),
          'participants': 189,
          'habits': [
            {'title': 'No sugar', 'icon': '🍰', 'targetValue': 1, 'targetUnit': 'day', 'incrementStep': 1, 'habitType': 'quit'},
            {'title': 'Drink water', 'icon': '💧', 'targetValue': 6, 'targetUnit': 'glasses', 'incrementStep': 1, 'habitType': 'build'},
          ],
        },
        {
          'id': 'reduce_caffeine',
          'title': 'Reduce Caffeine Intake',
          'endTime': now.add(const Duration(days: 21)),
          'description': 'Cut back on coffee and energy drinks. Limit to just 1 cup of coffee per day and feel more naturally energized without the crashes.',
          'icon': '☕',
          'color': const Color(0xFF795548),
          'participants': 76,
          'habits': [
            {'title': 'Max 1 coffee', 'icon': '☕', 'targetValue': 1, 'targetUnit': 'cup', 'incrementStep': 1, 'habitType': 'quit'},
            {'title': 'Drink herbal tea', 'icon': '🍵', 'targetValue': 2, 'targetUnit': 'cups', 'incrementStep': 1, 'habitType': 'build'},
          ],
        },
        {
          'id': 'no_procrastination',
          'title': 'Beat Procrastination',
          'endTime': now.add(const Duration(days: 14)),
          'description': 'Fight the urge to delay important tasks. Complete your top 3 priorities daily and stay focused with distraction-free work sessions.',
          'icon': '🎯',
          'color': const Color(0xFF009688),
          'participants': 134,
          'habits': [
            {'title': 'Complete 3 priorities', 'icon': '✅', 'targetValue': 3, 'targetUnit': 'tasks', 'incrementStep': 1, 'habitType': 'build'},
            {'title': 'No social media at work', 'icon': '📱', 'targetValue': 1, 'targetUnit': 'day', 'incrementStep': 1, 'habitType': 'quit'},
          ],
        },
        {
          'id': 'less_tv',
          'title': 'Less Screen Time',
          'endTime': now.add(const Duration(days: 14)),
          'description': 'Reduce TV and streaming to max 1 hour per day. Reclaim your time for hobbies, exercise, or quality time with loved ones.',
          'icon': '📺',
          'color': const Color(0xFF607D8B),
          'participants': 98,
          'habits': [
            {'title': 'Max 1h TV/Netflix', 'icon': '�', 'targetValue': 1, 'targetUnit': 'hour', 'incrementStep': 1, 'habitType': 'quit'},
            {'title': 'Go for a walk', 'icon': '🚶', 'targetValue': 20, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
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
    final habits = challenge['habits'] as List<dynamic>? ?? [];
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
                    '${habits.length} habits',
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
