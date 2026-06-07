import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:routiner/features/achievements/data/models/achievement_model.dart';
import 'package:routiner/features/achievements/data/services/achievement_service.dart';
import 'package:go_router/go_router.dart';
import 'package:routiner/l10n/app_localizations.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // User data
  String _userName = 'User';
  String? _avatarUrl;
  int _points = 0;
  int _friendsCount = 0;
  bool _isLoading = true;

  // Activity filter: 'month', 'week', 'day'
  String _activityFilter = 'month';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<int> _calculateTotalPoints(String userId) async {
    try {
      final logsQuery = await FirebaseFirestore.instance
          .collection('habitLogs')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .limit(1000)
          .get();

      return logsQuery.docs.length * 10;
    } catch (e) {
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('permission-denied') ||
          errorMsg.contains('permission denied')) {
        print('[PROFILE ERROR] Permission denied in _calculateTotalPoints');
        if (mounted) {
          await FirebaseAuth.instance.signOut();
          if (mounted) context.go('/auth');
        }
        return 0;
      }
      print('[PROFILE ERROR] Failed to calculate total points: $e');
      return 0;
    }
  }

  Future<void> _loadUserData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final totalPoints = await _calculateTotalPoints(user.uid);

        if (userDoc.exists) {
          final data = userDoc.data();
          final firstName = data?['firstName'] ?? '';
          final lastName = data?['lastName'] ?? '';
          final fullName = '$firstName $lastName'.trim();

          if (mounted) {
            setState(() {
              _userName = fullName.isNotEmpty
                  ? fullName
                  : (user.displayName ?? 'User');
              _avatarUrl = data?['avatarUrl'];
              _points = totalPoints;
            });
          }

          if ((data?['points'] ?? 0) != totalPoints) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'points': totalPoints});
          }
        } else {
          if (mounted) {
            setState(() {
              _userName = user.displayName ?? 'User';
              _points = totalPoints;
            });
          }
        }

        await _checkAndAwardAchievements(user.uid);
      }
    } catch (e) {
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('permission-denied') ||
          errorMsg.contains('permission denied')) {
        print('[PROFILE ERROR] Permission denied, user likely signed out');
        if (mounted) {
          await FirebaseAuth.instance.signOut();
          if (mounted) context.go('/auth');
        }
        return;
      }
      print('[PROFILE ERROR] Failed to load user data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkAndAwardAchievements(String userId) async {
    try {
      final achievementService = AchievementService();

      await achievementService.checkAndAwardPointsAchievements(userId);
      await achievementService.checkAndAwardStreakAchievements(userId);
      await achievementService.checkAndAwardFirstHabitAchievement(userId);
      await achievementService.checkAndAwardAnyHabitAchievement(userId);

      print('[PROFILE] Achievement check completed for user: $userId');
    } catch (e) {
      print('[PROFILE ERROR] Failed to check achievements: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUserData,
          child: Column(
            children: [
              _buildHeader(),
              _buildProfileInfo(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActivityTab(),
                    _buildAchievementsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.l10n.translate('profile'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EDF5)),
            ),
            child: IconButton(
              onPressed: () {
                context.push('/settings');
              },
              icon: const Icon(
                Icons.settings_outlined,
                color: Colors.grey,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: _buildAvatar(_avatarUrl),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🔥',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_points ${context.l10n.translate('points')}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, {double size = 30}) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return _buildDefaultAvatar();
    }

    if (avatarUrl.startsWith('data:image')) {
      try {
        final commaIndex = avatarUrl.indexOf(',');
        if (commaIndex != -1) {
          final base64String = avatarUrl.substring(commaIndex + 1);
          final bytes = base64Decode(base64String);

          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildDefaultAvatar(),
          );
        }
      } catch (e) {
        print('[PROFILE ERROR] Failed to decode base64 avatar: $e');
      }
      return _buildDefaultAvatar();
    }

    return Image.network(
      avatarUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppColors.blue100,
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDF5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.blue100,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: context.l10n.translate('activity')),
          Tab(text: context.l10n.translate('achievements')),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildEmptyState(
        context.l10n.translate('noActivityYet'),
        context.l10n.translate('startCompletingHabits'),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getActivityFilterText(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE8EDF5)),
                ),
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    setState(() {
                      _activityFilter = value;
                    });
                  },
                  icon: const Icon(
                    Icons.tune,
                    color: Colors.black54,
                    size: 18,
                  ),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE8EDF5)),
                  ),
                  elevation: 4,
                  offset: const Offset(0, 40),
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'day',
                      child: Row(
                        children: [
                          Icon(
                            Icons.today,
                            size: 18,
                            color: _activityFilter == 'day'
                                ? AppColors.blue100
                                : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            context.l10n.translate('today'),
                            style: TextStyle(
                              fontWeight: _activityFilter == 'day'
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: _activityFilter == 'day'
                                  ? AppColors.blue100
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'week',
                      child: Row(
                        children: [
                          Icon(
                            Icons.view_week,
                            size: 18,
                            color: _activityFilter == 'week'
                                ? AppColors.blue100
                                : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            context.l10n.translate('lastWeek'),
                            style: TextStyle(
                              fontWeight: _activityFilter == 'week'
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: _activityFilter == 'week'
                                  ? AppColors.blue100
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'month',
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 18,
                            color: _activityFilter == 'month'
                                ? AppColors.blue100
                                : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            context.l10n.translate('lastMonth'),
                            style: TextStyle(
                              fontWeight: _activityFilter == 'month'
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: _activityFilter == 'month'
                                  ? AppColors.blue100
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _ActivitiesStreamBuilder(
            userId: user.uid,
            activityFilter: _activityFilter,
          ),
        ),
      ],
    );
  }

  String _getActivityFilterText() {
    switch (_activityFilter) {
      case 'day':
        return context.l10n.translate('today');
      case 'week':
        return context.l10n.translate('lastWeek');
      case 'month':
      default:
        return context.l10n.translate('lastMonth');
    }
  }

  Widget _buildAchievementsTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return _AchievementsStreamBuilder(userId: user.uid);
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// StreamBuilder для активностей — реактивное обновление
class _ActivitiesStreamBuilder extends StatelessWidget {
  final String userId;
  final String activityFilter;

  const _ActivitiesStreamBuilder({
    required this.userId,
    required this.activityFilter,
  });

  @override
  Widget build(BuildContext context) {
    // Стрим привычек пользователя для маппинга habitId -> habitName
    final habitsStream = FirebaseFirestore.instance
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .snapshots();

    // Стрим логов привычек
    final logsStream = FirebaseFirestore.instance
        .collection('habitLogs')
        .where('userId', isEqualTo: userId)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: habitsStream,
      builder: (context, habitsSnapshot) {
        // Собираем маппинг habitId -> name
        final habitNames = <String, String>{};
        if (habitsSnapshot.hasData) {
          for (final doc in habitsSnapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data != null) {
              final name = data['name'] as String?;
              if (name != null && name.isNotEmpty) {
                habitNames[doc.id] = name;
              }
            }
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: logsStream,
          builder: (context, logsSnapshot) {
            if (logsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (logsSnapshot.hasError) {
              print('[ACTIVITIES STREAM ERROR] ${logsSnapshot.error}');
              return _buildEmptyState(context);
            }

            final docs = logsSnapshot.data?.docs ?? [];
            final activities =
                _processActivities(context, docs, habitNames);

            if (activities.isEmpty) {
              return _buildEmptyState(context);
            }

            return RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 300));
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  return _ActivityItem(activity: activities[index]);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.translate('noActivityYet'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.translate('startCompletingHabits'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _processActivities(
    BuildContext context,
    List<QueryDocumentSnapshot> docs,
    Map<String, String> habitNames,
  ) {
    final now = DateTime.now();
    DateTime cutoffDate;

    switch (activityFilter) {
      case 'day':
        cutoffDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        cutoffDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
      default:
        cutoffDate = now.subtract(const Duration(days: 30));
        break;
    }

    final activities = <Map<String, dynamic>>[];

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      final date = (data['date'] as Timestamp?)?.toDate();
      if (date == null || date.isBefore(cutoffDate)) continue;

      final status = data['status'] as String?;
      final habitId = data['habitId'] as String?;
      final habitName = (habitId != null ? habitNames[habitId] : null) ?? 'Habit';

      if (status == 'completed') {
        activities.add({
          'type': 'completed',
          'title':
              '${context.l10n.translate('completed')} "$habitName"',
          'subtitle': _formatTime(context, date),
          'date': date,
          'points': 10,
          'icon': 'up',
        });
      } else if (status == 'failed') {
        activities.add({
          'type': 'failed',
          'title':
              '${context.l10n.translate('failed')} "$habitName"',
          'subtitle': _formatTime(context, date),
          'date': date,
          'points': 0,
          'icon': 'down',
        });
      } else if (status == 'skipped') {
        activities.add({
          'type': 'skipped',
          'title':
              '${context.l10n.translate('skipped')} "$habitName"',
          'subtitle': _formatTime(context, date),
          'date': date,
          'points': 0,
          'icon': 'skip',
        });
      }
    }

    activities.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    return activities;
  }

  static String _formatTime(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    String dayText;
    if (dateDay.isAtSameMomentAs(today)) {
      dayText = context.l10n.translate('today');
    } else if (dateDay.isAtSameMomentAs(yesterday)) {
      dayText = context.l10n.translate('yesterday');
    } else {
      dayText = DateFormat('d MMM').format(date);
    }

    final timeText = DateFormat('h:mm a').format(date);
    return '$dayText, $timeText';
  }
}

/// StreamBuilder для достижений — реактивное обновление
class _AchievementsStreamBuilder extends StatelessWidget {
  final String userId;

  const _AchievementsStreamBuilder({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('achievements')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('[ACHIEVEMENTS STREAM ERROR] ${snapshot.error}');
          return const SizedBox();
        }

        final docs = snapshot.data?.docs ?? [];
        final achievements = _processAchievements(docs);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${achievements.length} ${context.l10n.translate('achievements')}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.push('/all_achievements');
                    },
                    child: Text(
                      context.l10n.translate('viewAll'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.purple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: achievements.isEmpty
                  ? _buildEmptyState(context)
                  : RefreshIndicator(
                      onRefresh: () async {
                        await Future.delayed(
                            const Duration(milliseconds: 300));
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: achievements.length,
                        itemBuilder: (context, index) {
                          return _AchievementItem(
                              achievement: achievements[index]);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 200,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.purple,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                context.push('/all_achievements');
              },
              child: Center(
                child: Text(
                  context.l10n.translate('getStarted'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: Text(
            context.l10n.translate('keepGoingToUnlock'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  List<AchievementModel> _processAchievements(
    List<QueryDocumentSnapshot> docs,
  ) {
    final achievements = <AchievementModel>[];

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      try {
        final achievement = AchievementModel.fromFirestore(data, doc.id);
        achievements.add(achievement);
      } catch (e) {
        print('[PROFILE ERROR] Failed to parse achievement ${doc.id}: $e');
      }
    }

    achievements.sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
    return achievements;
  }
}

class _ActivityItem extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    final icon = activity['icon'] as String;
    final points = activity['points'] as int? ?? 0;

    Widget iconWidget;

    if (icon == 'up') {
      iconWidget = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.arrow_upward,
          color: Color(0xFF4CAF50),
          size: 20,
        ),
      );
    } else if (icon == 'down') {
      iconWidget = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.arrow_downward,
          color: Color(0xFFEF5350),
          size: 20,
        ),
      );
    } else if (icon == 'skip') {
      iconWidget = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.skip_next,
          color: Color(0xFF2196F3),
          size: 20,
        ),
      );
    } else {
      iconWidget = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          '🏆',
          style: TextStyle(fontSize: 20),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        activity['title'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    if (points > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 16, left: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFA000).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+$points',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFFA000),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activity['subtitle'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          iconWidget,
        ],
      ),
    );
  }
}

class _AchievementItem extends StatelessWidget {
  final AchievementModel achievement;

  const _AchievementItem({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final localizedTitle =
        _getLocalizedAchievementTitle(context, achievement.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                achievement.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizedTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatRelativeTime(context, achievement.earnedAt),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _getLocalizedAchievementTitle(
      BuildContext context, String achievementId) {
    switch (achievementId) {
      case 'first_habit':
        return context.l10n.translate('firstHabit');
      case 'any_habit':
        return context.l10n.translate('habitMaster');
      case 'points_100':
        return context.l10n.translate('firstSteps');
      case 'points_500':
        return context.l10n.translate('risingStar');
      case 'points_1000':
        return context.l10n.translate('pointMaster');
      case 'streak_7':
        return context.l10n.translate('weekWarrior');
      case 'streak_30':
        return context.l10n.translate('monthlyChampion');
      case 'club_first':
        return context.l10n.translate('clubMember');
      case 'club_5':
        return context.l10n.translate('socialButterfly');
      case 'challenge_first':
        return context.l10n.translate('challengeBeginner');
      case 'challenge_5':
        return context.l10n.translate('challengeExpert');
      default:
        return achievementId
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) =>
                word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join(' ');
    }
  }

  static String _formatRelativeTime(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return context.l10n.translate('today');
    } else if (diff.inDays == 1) {
      return context.l10n.translate('yesterday');
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ${context.l10n.translate('daysAgo')}';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} ${context.l10n.translate('weeksAgo')}';
    } else if (diff.inDays < 365) {
      return '${(diff.inDays / 30).floor()} ${context.l10n.translate('monthsAgo')}';
    } else {
      return '${(diff.inDays / 365).floor()} ${context.l10n.translate('yearsAgo')}';
    }
  }
}
