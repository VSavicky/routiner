import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/features/achievements/data/models/achievement_model.dart';
import 'package:routiner/features/achievements/data/repositories/achievement_repository.dart';
import 'package:routiner/features/achievements/data/services/achievement_service.dart';
import 'package:routiner/l10n/app_localizations.dart';

class AllAchievementsScreen extends StatefulWidget {
  const AllAchievementsScreen({super.key});

  @override
  State<AllAchievementsScreen> createState() => _AllAchievementsScreenState();
}

class _AllAchievementsScreenState extends State<AllAchievementsScreen> {
  final AchievementService _achievementService = AchievementService();
  final AchievementRepository _achievementRepository = AchievementRepository();
  bool _isLoading = false;
  List<AchievementModel> _userAchievements = [];
  List<Map<String, dynamic>> _allAchievements = [];

  @override
  void initState() {
    super.initState();
    _loadUserAchievements();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAllAchievements();
  }

  Future<void> _loadAllAchievements() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    // Get all possible achievements
    final allAchievements = [
      // First habit achievement
      {
        'id': 'first_habit',
        'title': context.l10n.translate('firstHabit'),
        'description': context.l10n.translate('completeFirstHabit'),
        'icon': '🌟',
        'type': 'habit',
        'color': '#4CAF50',
        'requirements': [
          context.l10n.translate('completeFirstHabit'),
          context.l10n.translate('startJourney'),
          context.l10n.translate('buildConsistency'),
        ],
        'isUnlocked': false,
      },
      // Any habit achievement
      {
        'id': 'any_habit',
        'title': context.l10n.translate('habitMaster'),
        'description': context.l10n.translate('completeAnyHabit'),
        'icon': '✅',
        'type': 'habit',
        'color': '#4CAF50',
        'requirements': [
          context.l10n.translate('completeAnyHabitSuccessfully'),
          context.l10n.translate('startJourney'),
          context.l10n.translate('buildConsistency'),
        ],
        'isUnlocked': false,
      },
      // Points achievements
      {
        'id': 'points_100',
        'title': context.l10n.translate('firstSteps'),
        'description': context.l10n.translate('earnFirst100Points'),
        'icon': '🌟',
        'type': 'points',
        'color': '#4CAF50',
        'requirements': [
          context.l10n.translate('complete10Habits'),
          context.l10n.translate('collect100Points'),
          context.l10n.translate('reachBeginnerLevel'),
        ],
        'isUnlocked': false,
      },
      {
        'id': 'points_500',
        'title': context.l10n.translate('risingStar'),
        'description': context.l10n.translate('earn500Points'),
        'icon': '⭐',
        'type': 'points',
        'color': '#FF9800',
        'requirements': [
          context.l10n.translate('complete50Habits'),
          context.l10n.translate('collect500Points'),
          context.l10n.translate('reachIntermediateLevel'),
        ],
        'isUnlocked': false,
      },
      {
        'id': 'points_1000',
        'title': context.l10n.translate('pointMaster'),
        'description': context.l10n.translate('earn1000Points'),
        'icon': '🏆',
        'type': 'points',
        'color': '#FF5722',
        'requirements': [
          context.l10n.translate('complete100Habits'),
          context.l10n.translate('collect1000Points'),
          context.l10n.translate('reachExpertLevel'),
        ],
        'isUnlocked': false,
      },
      // Streak achievements
      {
        'id': 'streak_7',
        'title': context.l10n.translate('weekWarrior'),
        'description': context.l10n.translate('maintain7DayStreak'),
        'icon': '🔥',
        'type': 'streak',
        'color': '#FF6B35',
        'requirements': [
          context.l10n.translate('complete7ConsecutiveDays'),
          context.l10n.translate('dontSkipAnyDay'),
          context.l10n.translate('buildWeeklyHabits'),
        ],
        'isUnlocked': false,
      },
      {
        'id': 'streak_30',
        'title': context.l10n.translate('monthlyChampion'),
        'description': context.l10n.translate('maintain30DayStreak'),
        'icon': '💪',
        'type': 'streak',
        'color': '#E91E63',
        'requirements': [
          context.l10n.translate('complete30ConsecutiveDays'),
          context.l10n.translate('buildMonthlyHabits'),
          context.l10n.translate('stayOnPathToSuccess'),
        ],
        'isUnlocked': false,
      },
      // Club achievements
      {
        'id': 'club_first',
        'title': context.l10n.translate('clubMember'),
        'description': context.l10n.translate('joinFirstClub'),
        'icon': '👥',
        'type': 'club',
        'color': '#2196F3',
        'requirements': [
          context.l10n.translate('findInterestingClub'),
          context.l10n.translate('joinCommunity'),
          context.l10n.translate('startCommunicating'),
        ],
        'isUnlocked': false,
      },
      {
        'id': 'club_5',
        'title': context.l10n.translate('socialButterfly'),
        'description': context.l10n.translate('join5Clubs'),
        'icon': '🦋',
        'type': 'club',
        'color': '#9C27B0',
        'requirements': [
          context.l10n.translate('exploreDifferentClubs'),
          context.l10n.translate('find5Communities'),
          context.l10n.translate('becomeActiveParticipant'),
        ],
        'isUnlocked': false,
      },
      // Challenge achievements
      {
        'id': 'challenge_first',
        'title': context.l10n.translate('challengeBeginner'),
        'description': context.l10n.translate('completeFirstChallenge'),
        'icon': '🏅',
        'type': 'challenge',
        'color': '#00BCD4',
        'requirements': [
          context.l10n.translate('findInterestingChallenge'),
          context.l10n.translate('followInstructions'),
          context.l10n.translate('completeToEnd'),
        ],
        'isUnlocked': false,
      },
      {
        'id': 'challenge_5',
        'title': context.l10n.translate('challengeExpert'),
        'description': context.l10n.translate('complete5Challenges'),
        'icon': '🎯',
        'type': 'challenge',
        'color': '#673AB7',
        'requirements': [
          context.l10n.translate('complete5Challenges'),
          context.l10n.translate('tryDifferentTasks'),
          context.l10n.translate('showWillpower'),
        ],
        'isUnlocked': false,
      },
    ];

    setState(() {
      _allAchievements = allAchievements;
      _isLoading = false;
    });
  }

  Future<void> _loadUserAchievements() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final achievements = await _achievementRepository.getUserAchievements(user.uid);
      setState(() {
        _userAchievements = achievements;
      });
    }
  }

  bool _isAchievementUnlocked(String achievementId) {
    return _userAchievements.any((achievement) {
      // Проверяем по ID или по названию для надежности
      return achievement.id == achievementId || 
             achievement.metadata?['achievementId'] == achievementId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FD),
        elevation: 0,
        title: Text(
          context.l10n.translate('allAchievements'),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadUserAchievements();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _allAchievements.length,
                itemBuilder: (context, index) {
                  final achievement = _allAchievements[index];
                  final isUnlocked = _isAchievementUnlocked(achievement['id']);
                  return _buildAchievementCard(achievement, isUnlocked);
                },
              ),
            ),
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement, bool isUnlocked) {
    final color = achievement['color'] != null 
        ? _parseColor(achievement['color'] as String)
        : (isUnlocked ? const Color(0xFF4CAF50) : Colors.grey[400]!);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isUnlocked 
            ? Border.all(color: color, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isUnlocked 
                      ? color.withOpacity(0.1)
                      : Colors.grey[200]!,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    achievement['icon'],
                    style: TextStyle(
                      fontSize: 28,
                      color: isUnlocked ? null : Colors.grey[400],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            achievement['title'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? Colors.black : Colors.grey[600],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isUnlocked 
                                ? color
                                : Colors.grey[300]!,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isUnlocked ? context.l10n.translate('completed') : context.l10n.translate('locked'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      achievement['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: isUnlocked ? Colors.grey[700] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnlocked 
                  ? color.withOpacity(0.1)
                  : Colors.grey[100]!,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.translate('requirements'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isUnlocked ? color : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                ...achievement['requirements'].map<Widget>((requirement) => 
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isUnlocked 
                            ? color.withOpacity(0.05)
                            : Colors.grey[50]!,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isUnlocked 
                              ? color.withOpacity(0.3)
                              : Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isUnlocked 
                                  ? color
                                  : Colors.grey[400]!,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            requirement,
                            style: TextStyle(
                              fontSize: 12,
                              color: isUnlocked ? Colors.grey[700] : Colors.grey[600],
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    switch (colorString) {
      case '#4CAF50':
        return const Color(0xFF4CAF50);
      case '#FF9800':
        return const Color(0xFFFF9800);
      case '#FF5722':
        return const Color(0xFFFF5722);
      case '#FF6B35':
        return const Color(0xFFFF6B35);
      case '#E91E63':
        return const Color(0xFFE91E63);
      case '#2196F3':
        return const Color(0xFF2196F3);
      case '#9C27B0':
        return const Color(0xFF9C27B0);
      case '#00BCD4':
        return const Color(0xFF00BCD4);
      case '#673AB7':
        return const Color(0xFF673AB7);
      default:
        return const Color(0xFF4CAF50);
    }
  }
}
