import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:routiner/features/achievements/data/models/achievement_model.dart';
import 'package:routiner/features/achievements/data/repositories/achievement_repository.dart';
import 'package:routiner/features/achievements/data/services/achievement_service.dart';
import 'package:go_router/go_router.dart';
import 'package:routiner/l10n/app_localizations.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // User data
  String _userName = 'User';
  String? _avatarUrl;
  int _points = 0;
  int _friendsCount = 0;
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _friends = [];
  List<AchievementModel> _achievements = [];
  bool _isLoading = true;
  
  // Activity filter: 'month', 'week', 'day'
  String _activityFilter = 'month';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadUserData();
    
    // Слушаем возвращение с других экранов
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Обновляем данные когда экран становится активным снова
    _loadUserData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }
  
  // Подсчет очков из ВСЕХ выполненных привычек пользователя
  Future<int> _calculateTotalPoints(String userId) async {
    try {
      final logsQuery = await FirebaseFirestore.instance
          .collection('habitLogs')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .limit(1000) // Ограничиваем для быстрой загрузки
          .get();
      
      // 10 очков за каждую выполненную привычку
      return logsQuery.docs.length * 10;
    } catch (e) {
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
        // Load user profile
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        // Считаем реальные очки из всех выполненных привычек
        final totalPoints = await _calculateTotalPoints(user.uid);
        
        if (userDoc.exists) {
          final data = userDoc.data();
          final firstName = data?['firstName'] ?? '';
          final lastName = data?['lastName'] ?? '';
          final fullName = '$firstName $lastName'.trim();
          
          if (mounted) {
            setState(() {
              _userName = fullName.isNotEmpty ? fullName : (user.displayName ?? 'User');
              _avatarUrl = data?['avatarUrl'];
              _points = totalPoints; // Реальные очки из всех выполненных привычек
            });
          }
          
          // Обновляем поле points в БД для синхронизации
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
        
        // Загружаем все данные параллельно для ускорения
        final futures = <Future>[];
        
        // Load activities (logs from last month)
        futures.add(_loadActivities(user.uid));
        
        // Load friends (mock data for now - will be from friends collection)
        futures.add(_loadFriends(user.uid));
        
        // Load achievements
        futures.add(_loadAchievements(user.uid));
        
        // Ждем выполнения всех запросов параллельно
        await Future.wait(futures);
        
        // Check and award achievements (после загрузки данных)
        await _checkAndAwardAchievements(user.uid);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
      
      // Check points achievements
      await achievementService.checkAndAwardPointsAchievements(userId);
      
      // Check streak achievements
      await achievementService.checkAndAwardStreakAchievements(userId);
      
      // Check first habit achievement
      await achievementService.checkAndAwardFirstHabitAchievement(userId);
      
      // Check any habit achievement (5+ habits)
      await achievementService.checkAndAwardAnyHabitAchievement(userId);
      
      print('[PROFILE] Achievement check completed for user: $userId');
    } catch (e) {
      print('[PROFILE ERROR] Failed to check achievements: $e');
    }
  }
  
  Future<void> _loadActivities(String userId) async {
    try {
      final now = DateTime.now();
      DateTime cutoffDate;
      
      // Определяем период фильтра
      switch (_activityFilter) {
        case 'day':
          cutoffDate = DateTime(now.year, now.month, now.day); // Сегодня с 00:00
          break;
        case 'week':
          cutoffDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
        default:
          cutoffDate = now.subtract(const Duration(days: 30));
          break;
      }
      
      // Get logs directly from Firestore
      final logsQuery = await FirebaseFirestore.instance
          .collection('habitLogs')
          .where('userId', isEqualTo: userId)
          .get();
      
      final activities = <Map<String, dynamic>>[];
      
      for (final doc in logsQuery.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final status = data['status'] as String?;
        final habitId = data['habitId'] as String?;
        
        // Фильтруем по дате на клиенте
        if (date.isBefore(cutoffDate)) continue;
        
        // Получаем название привычки
        String habitName = 'Habit';
        if (habitId != null) {
          try {
            final habitDoc = await FirebaseFirestore.instance
                .collection('habits')
                .doc(habitId)
                .get();
            if (habitDoc.exists) {
              habitName = habitDoc.data()?['name'] ?? 'Habit';
            }
          } catch (e) {
            // Игнорируем ошибку, используем дефолтное название
          }
        }
        
        final localizedHabitName = _getLocalizedHabitName(habitName);
        
        if (status == 'completed') {
          activities.add({
            'type': 'completed',
            'title': '${context.l10n.translate('completed')} "$localizedHabitName"',
            'subtitle': _formatTime(date),
            'date': date,
            'points': 10,
            'icon': 'up',
          });
        } else if (status == 'failed') {
          activities.add({
            'type': 'failed',
            'title': '${context.l10n.translate('failed')} "$localizedHabitName"',
            'subtitle': _formatTime(date),
            'date': date,
            'points': 0,
            'icon': 'down',
          });
        } else if (status == 'skipped') {
          activities.add({
            'type': 'skipped',
            'title': '${context.l10n.translate('skipped')} "$localizedHabitName"',
            'subtitle': _formatTime(date),
            'date': date,
            'points': 0,
            'icon': 'skip',
          });
        }
      }
      
      // Сортируем по дате (новые сверху)
      activities.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      
      setState(() {
        _activities = activities;
      });
    } catch (e) {
      print('[PROFILE ERROR] Failed to load activities: $e');
    }
  }
    
  Future<void> _loadFriends(String userId) async {
    try {
      // For now, mock friends data
      // In real app, this would come from a 'friends' collection
      final friendsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .limit(10)
          .get();
      
      final friends = <Map<String, dynamic>>[];
      
      for (final doc in friendsSnapshot.docs) {
        if (doc.id != userId) {
          final data = doc.data();
          friends.add({
            'id': doc.id,
            'name': data['displayName'] ?? 'User',
            'avatarUrl': data['avatarUrl'],
            'points': data['points'] ?? 0,
          });
        }
      }
      
      setState(() {
        _friends = friends;
        _friendsCount = friends.length;
      });
    } catch (e) {
      print('[PROFILE ERROR] Failed to load friends: $e');
    }
  }
  
  Future<void> _loadAchievements(String userId) async {
    try {
      // Get achievements directly from Firestore like activities
      final achievementsQuery = await FirebaseFirestore.instance
          .collection('achievements')
          .where('userId', isEqualTo: userId)
          .limit(50) // Ограничиваем для быстрой загрузки
          .get();
      
      final achievements = <AchievementModel>[];
      
      for (final doc in achievementsQuery.docs) {
        final data = doc.data();
        
        try {
          final achievement = AchievementModel.fromFirestore(data, doc.id);
          achievements.add(achievement);
        } catch (e) {
          print('[PROFILE ERROR] Failed to parse achievement ${doc.id}: $e');
        }
      }
      
      // Сортируем по дате (новые сверху)
      achievements.sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
      
      if (mounted) {
        setState(() {
          _achievements = achievements;
        });
      }
    } catch (e) {
      print('[PROFILE ERROR] Failed to load achievements: $e');
    }
  }

    
  String _formatTime(DateTime date) {
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
  
  String _formatRelativeTime(DateTime date) {
    if (!mounted) {
      // Fallback для случая когда контекст не готов
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays == 0) {
        return 'Today';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
      } else if (diff.inDays < 30) {
        return '${(diff.inDays / 7).floor()} weeks ago';
      } else if (diff.inDays < 365) {
        return '${(diff.inDays / 30).floor()} months ago';
      } else {
        return '${(diff.inDays / 365).floor()} years ago';
      }
    }
    
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Обновляем данные пользователя
            await _loadUserData();
          },
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
              icon: Icon(
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
  
  /// Вспомогательный метод для отображения аватара (поддерживает base64 и network URL)
  Widget _buildAvatar(String? avatarUrl, {double size = 30}) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return _buildDefaultAvatar();
    }
    
    // Проверяем если это base64 data URL
    if (avatarUrl.startsWith('data:image')) {
      try {
        // Извлекаем base64 часть из data URL
        final commaIndex = avatarUrl.indexOf(',');
        if (commaIndex != -1) {
          final base64String = avatarUrl.substring(commaIndex + 1);
          final bytes = base64Decode(base64String);
          
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
          );
        }
      } catch (e) {
        print('[PROFILE ERROR] Failed to decode base64 avatar: $e');
      }
      return _buildDefaultAvatar();
    }
    
    // Иначе используем network URL
    return Image.network(
      avatarUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
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

  String _getActivityFilterText() {
    if (!mounted) {
      // Fallback для случая когда контекст не готов
      switch (_activityFilter) {
        case 'day':
          return 'Showing today activity';
        case 'week':
          return 'Showing last week activity';
        case 'month':
        default:
          return 'Showing last month activity';
      }
    }
    
    switch (_activityFilter) {
      case 'day':
        return context.l10n.translate('showing_today_activity');
      case 'week':
        return context.l10n.translate('showing_last_week_activity');
      case 'month':
      default:
        return context.l10n.translate('showing_last_month_activity');
    }
  }

  void _onFilterChanged(String newFilter) {
    setState(() {
      _activityFilter = newFilter;
    });
    // Перезагружаем активности с новым фильтром
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _loadActivities(user.uid);
    }
  }

  Widget _buildActivityTab() {
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
                  onSelected: _onFilterChanged,
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
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'day',
                      child: Row(
                        children: [
                          Icon(
                            Icons.today,
                            size: 18,
                            color: _activityFilter == 'day' ? AppColors.blue100 : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            context.l10n.translate('today'),
                            style: TextStyle(
                              fontWeight: _activityFilter == 'day' ? FontWeight.w600 : FontWeight.normal,
                              color: _activityFilter == 'day' ? AppColors.blue100 : Colors.black87,
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
                            color: _activityFilter == 'week' ? AppColors.blue100 : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            context.l10n.translate('lastWeek'),
                            style: TextStyle(
                              fontWeight: _activityFilter == 'week' ? FontWeight.w600 : FontWeight.normal,
                              color: _activityFilter == 'week' ? AppColors.blue100 : Colors.black87,
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
                            color: _activityFilter == 'month' ? AppColors.blue100 : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            context.l10n.translate('lastMonth'),
                            style: TextStyle(
                              fontWeight: _activityFilter == 'month' ? FontWeight.w600 : FontWeight.normal,
                              color: _activityFilter == 'month' ? AppColors.blue100 : Colors.black87,
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _activities.isEmpty
                  ? _buildEmptyState(context.l10n.translate('noActivityYet'), context.l10n.translate('startCompletingHabits'))
                  : RefreshIndicator(
                      onRefresh: () async {
                        // Обновляем данные при pull-to-refresh
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          await _loadUserData();
                        }
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(), // Важно для работы RefreshIndicator
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _activities.length,
                        itemBuilder: (context, index) {
                          return _buildActivityItem(_activities[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }
  
  Widget _buildActivityItem(Map<String, dynamic> activity) {
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
      // Green color for success
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
      // Red color for failure
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
      // Blue color for skipped
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
      // Orange color for achievement
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
                  crossAxisAlignment: CrossAxisAlignment.center, // Центрируем по вертикали
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
                        padding: const EdgeInsets.only(right: 16, left: 8), // Отступы от иконки и от текста
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
  
  Widget _buildFriendItem(Map<String, dynamic> friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE8EDF5)),
            ),
            child: ClipOval(
              child: _buildAvatar(friend['avatarUrl']),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend['name'] as String,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${friend['points']} ${context.l10n.translate('points')}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Remove friend
            },
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.grey,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDefaultFriendAvatar(String name) {
    return Container(
      color: AppColors.blue100.withOpacity(0.2),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: AppColors.blue100,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
  
  Widget _buildAchievementsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_achievements.length} ${context.l10n.translate('achievements')}',
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _achievements.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          width: 200,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.purple, // Фиолетовый цвет из AppColors
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
                        Text(
                          context.l10n.translate('keepGoingToUnlock'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          await _loadUserData();
                        }
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _achievements.length,
                        itemBuilder: (context, index) {
                          return _buildAchievementItem(_achievements[index]);
                        },
                        shrinkWrap: true,
                      ),
                    ),
        ),
      ],
    );
  }
  
  Widget _buildAchievementItem(AchievementModel achievement) {
    // Локализуем название достижения при отображении
    final localizedTitle = _getLocalizedAchievementTitle(achievement.id);
    
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
                  _formatRelativeTime(achievement.earnedAt),
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

  String _getLocalizedHabitName(String habitName) {
    // Маппинг известных названий привычек на локализованные версии
    switch (habitName.toLowerCase()) {
      case 'recovery stretching':
        return context.l10n.translate('recoveryStretching');
      case 'protein intake':
        return context.l10n.translate('proteinIntake');
      case 'strength training':
        return context.l10n.translate('strengthTraining');
      case 'walk':
        return context.l10n.translate('walk');
      case 'meditate':
        return context.l10n.translate('meditate');
      case 'read':
        return context.l10n.translate('read');
      case 'drink water':
        return context.l10n.translate('drinkWater');
      case 'less sugar':
        return context.l10n.translate('lessSugar');
      default:
        return habitName; // Возвращаем как есть если неизвестная привычка
    }
  }

  String _getLocalizedAchievementTitle(String achievementId) {
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
        return achievementId.replaceAll('_', ' ').split(' ').map((word) => 
          word[0].toUpperCase() + word.substring(1).toLowerCase()
        ).join(' ');
    }
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
