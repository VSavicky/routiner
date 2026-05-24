import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/l10n/app_localizations.dart';
import 'package:routiner/features/achievements/data/models/achievement_model.dart';
import 'dart:convert';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final int points;
  final String? avatarUrl;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.points,
    this.avatarUrl,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  
  List<Map<String, dynamic>> _activities = [];
  List<AchievementModel> _achievements = [];
  bool _isLoading = true;
  int _calculatedPoints = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Обновляем данные когда приложение становится активным
    if (state == AppLifecycleState.resumed) {
      _loadUserData();
    }
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  /// Метод для перезагрузки данных (вызывается при возврате с других экранов)
  void reload() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      // Загружаем активности пользователя
      await _loadActivities();
      
      // Загружаем достижения пользователя
      await _loadAchievements();
      
      // Считаем реальные очки
      final totalPoints = await _calculateTotalPoints(widget.userId);
      
      if (mounted) {
        setState(() {
          _calculatedPoints = totalPoints;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[USER PROFILE ERROR] Failed to load data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
      print('[USER PROFILE ERROR] Failed to calculate points: $e');
      return 0;
    }
  }

  Future<void> _loadActivities() async {
    try {
      final now = DateTime.now();
      final cutoffDate = now.subtract(const Duration(days: 30));
      
      final logsQuery = await FirebaseFirestore.instance
          .collection('habitLogs')
          .where('userId', isEqualTo: widget.userId)
          .get();
      
      final activities = <Map<String, dynamic>>[];
      
      for (final doc in logsQuery.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final status = data['status'] as String?;
        final habitId = data['habitId'] as String?;
        
        // Фильтруем только последние 30 дней
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
            // Игнорируем ошибку
          }
        }
        
        if (status == 'completed') {
          activities.add({
            'type': 'completed',
            'title': 'Выполнено "$habitName"',
            'subtitle': _formatTime(date),
            'date': date,
            'points': 10,
            'icon': 'up',
          });
        } else if (status == 'failed') {
          activities.add({
            'type': 'failed',
            'title': 'Провалено "$habitName"',
            'subtitle': _formatTime(date),
            'date': date,
            'points': 0,
            'icon': 'down',
          });
        } else if (status == 'skipped') {
          activities.add({
            'type': 'skipped',
            'title': 'Пропущено "$habitName"',
            'subtitle': _formatTime(date),
            'date': date,
            'points': 0,
            'icon': 'skip',
          });
        }
      }
      
      // Сортируем по дате (новые сверху)
      activities.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      
      if (mounted) {
        setState(() {
          _activities = activities;
        });
      }
    } catch (e) {
      print('[USER PROFILE ERROR] Failed to load activities: $e');
    }
  }

  Future<void> _loadAchievements() async {
    try {
      final achievementsQuery = await FirebaseFirestore.instance
          .collection('achievements')
          .where('userId', isEqualTo: widget.userId)
          .limit(50)
          .get();
      
      final achievements = <AchievementModel>[];
      
      for (final doc in achievementsQuery.docs) {
        try {
          final achievement = AchievementModel.fromFirestore(doc.data(), doc.id);
          achievements.add(achievement);
        } catch (e) {
          print('[USER PROFILE ERROR] Failed to parse achievement: $e');
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
      print('[USER PROFILE ERROR] Failed to load achievements: $e');
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);
    
    String dayText;
    if (dateDay.isAtSameMomentAs(today)) {
      dayText = 'Сегодня';
    } else if (dateDay.isAtSameMomentAs(yesterday)) {
      dayText = 'Вчера';
    } else {
      final months = [
        'янв', 'фев', 'мар', 'апр', 'май', 'июн',
        'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
      ];
      dayText = '${date.day} ${months[date.month - 1]}';
    }

    final hours = date.hour.toString().padLeft(2, '0');
    final minutes = date.minute.toString().padLeft(2, '0');
    return '$dayText, $hours:$minutes';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.black100,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Профиль',
          style: AppFonts.bodyTitleMedium.copyWith(
            color: AppColors.black100,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header с аватаром и информацией (на всю ширину)
                _buildHeader(),
                
                // Tab Bar
                _buildTabBar(),
                
                // Tab Bar View
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
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.black10,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.blue100,
        unselectedLabelColor: AppColors.black60,
        labelStyle: AppFonts.bodyTitleMedium.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppFonts.bodyTitleMedium.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w500,
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
    if (_activities.isEmpty) {
      return _buildEmptyState();
    }
    
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Последние ${_activities.length > 15 ? 15 : _activities.length} записей',
              style: AppFonts.bodyAlternative.copyWith(
                fontSize: 13,
                color: AppColors.black40,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(
              _activities.length > 15 ? 15 : _activities.length,
              (index) => _buildActivityItem(_activities[index]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isCurrentUser = widget.userId == FirebaseAuth.instance.currentUser?.uid;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.blue100,
            AppColors.blue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Аватар
          _buildAvatar(widget.avatarUrl),
          
          const SizedBox(height: 16),
          
          // Имя
          Text(
            widget.userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Очки
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star,
                  color: AppColors.orange,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  '$_calculatedPoints',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isCurrentUser ? 'ваших очков' : 'очков',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          if (isCurrentUser) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.orange10,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Это ваш профиль',
                style: AppFonts.bodyAlternative.copyWith(
                  fontSize: 12,
                  color: AppColors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAchievementsTab() {
    if (_achievements.isEmpty) {
      return _buildEmptyAchievementsState();
    }
    
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_achievements.length} ${_getAchievementsCountText()}',
              style: AppFonts.bodyAlternative.copyWith(
                fontSize: 13,
                color: AppColors.black40,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(
              _achievements.length > 10 ? 10 : _achievements.length,
              (index) => _buildAchievementItem(_achievements[index]),
            ),
          ],
        ),
      ),
    );
  }

  String _getAchievementsCountText() {
    final count = _achievements.length;
    if (count == 1) {
      return 'достижение';
    } else if (count >= 2 && count <= 4) {
      return 'достижения';
    } else {
      return 'достижений';
    }
  }

  Widget _buildAchievementItem(AchievementModel achievement) {
    final earnedAt = achievement.earnedAt;
    final now = DateTime.now();
    final diff = now.difference(earnedAt);
    
    String timeAgo;
    if (diff.inDays == 0) {
      timeAgo = 'Сегодня';
    } else if (diff.inDays == 1) {
      timeAgo = 'Вчера';
    } else if (diff.inDays < 7) {
      timeAgo = '${diff.inDays} ${_getDaysWord(diff.inDays)}';
    } else if (diff.inDays < 30) {
      timeAgo = '${(diff.inDays / 7).floor()} ${_getWeeksWord((diff.inDays / 7).floor())}';
    } else {
      timeAgo = '${(diff.inDays / 30).floor()} ${_getMonthsWord((diff.inDays / 30).floor())}';
    }

    // Локализация названия достижения
    final localizedTitle = _getLocalizedAchievementTitle(achievement.id);
    final localizedDescription = _getLocalizedAchievementDescription(achievement.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.black10,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Иконка достижения
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.orange10,
                  AppColors.orange.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.orange.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                achievement.icon,
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
          const SizedBox(width: 14),
          
          // Информация о достижении
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizedTitle,
                  style: AppFonts.bodyTitleMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                if (localizedDescription.isNotEmpty) ...[
                  Text(
                    localizedDescription,
                    style: AppFonts.bodyAlternative.copyWith(
                      fontSize: 11,
                      color: AppColors.black40,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  'Получено $timeAgo',
                  style: AppFonts.bodyAlternative.copyWith(
                    fontSize: 11,
                    color: AppColors.black40,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      default:
        return achievementId;
    }
  }

  String _getLocalizedAchievementDescription(String achievementId) {
    switch (achievementId) {
      case 'first_habit':
        return context.l10n.translate('completeFirstHabit');
      case 'any_habit':
        return context.l10n.translate('completeAnyHabit');
      case 'points_100':
        return context.l10n.translate('earnFirst100Points');
      case 'points_500':
        return context.l10n.translate('earn500Points');
      case 'points_1000':
        return context.l10n.translate('earn1000Points');
      case 'streak_7':
        return context.l10n.translate('maintain7DayStreak');
      case 'streak_30':
        return context.l10n.translate('maintain30DayStreak');
      case 'club_first':
        return context.l10n.translate('exploreDifferentClubs');
      default:
        return '';
    }
  }

  Widget _buildEmptyAchievementsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      color: Colors.white,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.black10,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              size: 40,
              color: AppColors.black40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Пока нет достижений',
            style: AppFonts.bodyTitleMedium.copyWith(
              color: AppColors.black100,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Выполняйте привычки и челленджи\nчтобы получить первые достижения',
            textAlign: TextAlign.center,
            style: AppFonts.bodyAlternative.copyWith(
              color: AppColors.black40,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _getDaysWord(int days) {
    if (days % 10 == 1 && days % 100 != 11) {
      return 'день';
    } else if (days % 10 >= 2 && days % 10 <= 4 && 
               (days % 100 < 10 || days % 100 >= 20)) {
      return 'дня';
    } else {
      return 'дней';
    }
  }

  String _getWeeksWord(int weeks) {
    if (weeks % 10 == 1 && weeks % 100 != 11) {
      return 'неделю';
    } else if (weeks % 10 >= 2 && weeks % 10 <= 4 && 
               (weeks % 100 < 10 || weeks % 100 >= 20)) {
      return 'недели';
    } else {
      return 'недель';
    }
  }

  String _getMonthsWord(int months) {
    if (months % 10 == 1 && months % 100 != 11) {
      return 'месяц';
    } else if (months % 10 >= 2 && months % 10 <= 4 && 
               (months % 100 < 10 || months % 100 >= 20)) {
      return 'месяца';
    } else {
      return 'месяцев';
    }
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final icon = activity['icon'] as String;
    final points = activity['points'] as int? ?? 0;
    
    Widget iconWidget;
    
    if (icon == 'up') {
      iconWidget = Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.green10, AppColors.green.withOpacity(0.2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.arrow_upward,
          color: AppColors.green,
          size: 22,
        ),
      );
    } else if (icon == 'down') {
      iconWidget = Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade50, Colors.red.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.arrow_downward,
          color: AppColors.red,
          size: 22,
        ),
      );
    } else if (icon == 'skip') {
      iconWidget = Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.blue10, AppColors.blue.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.skip_next,
          color: AppColors.blue100,
          size: 22,
        ),
      );
    } else {
      iconWidget = Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.orange10, AppColors.orange.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('🏆', style: TextStyle(fontSize: 22)),
      );
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.black10,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String,
                  style: AppFonts.bodyTitleMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['subtitle'] as String,
                  style: AppFonts.bodyAlternative.copyWith(
                    fontSize: 12,
                    color: AppColors.black40,
                  ),
                ),
              ],
            ),
          ),
          if (points > 0) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.orange10, AppColors.orange.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star,
                    color: AppColors.orange,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+$points',
                    style: AppFonts.bodyTitleMedium.copyWith(
                      fontSize: 13,
                      color: AppColors.orange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(width: 12),
          iconWidget,
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      color: Colors.white,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.black10,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_outlined,
              size: 40,
              color: AppColors.black40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Пока нет активности',
            style: AppFonts.bodyTitleMedium.copyWith(
              color: AppColors.black100,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Как только пользователь выполнит\nпривычки, они появятся здесь',
            textAlign: TextAlign.center,
            style: AppFonts.bodyAlternative.copyWith(
              color: AppColors.black40,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Вспомогательный метод для отображения аватара (поддерживает base64 и network URL)
  Widget _buildAvatar(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person, color: Colors.white, size: 48),
      );
    }
    
    // Проверяем если это base64 data URL
    if (avatarUrl.startsWith('data:image')) {
      try {
        // Извлекаем base64 часть из data URL
        final commaIndex = avatarUrl.indexOf(',');
        if (commaIndex != -1) {
          final base64String = avatarUrl.substring(commaIndex + 1);
          final bytes = base64Decode(base64String);
          
          return ClipOval(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Image.memory(
                bytes,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.person, color: Colors.white, size: 48),
              ),
            ),
          );
        }
      } catch (e) {
        print('[USER PROFILE ERROR] Failed to decode base64 avatar: $e');
      }
      return Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person, color: Colors.white, size: 48),
      );
    }
    
    // Иначе используем network URL
    return ClipOval(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Image.network(
          avatarUrl,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.person, color: Colors.white, size: 48),
        ),
      ),
    );
  }
}
