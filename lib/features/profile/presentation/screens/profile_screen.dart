import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
  List<Map<String, dynamic>> _achievements = [];
  bool _isLoading = true;
  
  // Activity filter: 'month', 'week', 'day'
  String _activityFilter = 'month';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
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
          .get();
      
      // 10 очков за каждую выполненную привычку
      return logsQuery.docs.length * 10;
    } catch (e) {
      print('[PROFILE ERROR] Failed to calculate total points: $e');
      return 0;
    }
  }
  
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
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
          
          setState(() {
            _userName = fullName.isNotEmpty ? fullName : (user.displayName ?? 'User');
            _avatarUrl = data?['avatarUrl'];
            _points = totalPoints; // Реальные очки из всех выполненных привычек
          });
          
          // Обновляем поле points в БД для синхронизации
          if ((data?['points'] ?? 0) != totalPoints) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'points': totalPoints});
          }
        } else {
          setState(() {
            _userName = user.displayName ?? 'User';
            _points = totalPoints;
          });
        }
        
        // Load activities (logs from last month)
        await _loadActivities(user.uid);
        
        // Load friends (mock data for now - will be from friends collection)
        await _loadFriends(user.uid);
        
        // Load achievements
        await _loadAchievements(user.uid);
      }
    } catch (e) {
      print('[PROFILE ERROR] Failed to load user data: $e');
    } finally {
      setState(() => _isLoading = false);
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
        
        if (status == 'completed') {
          activities.add({
            'type': 'completed',
            'title': 'Completed "$habitName"',
            'subtitle': _formatTime(date),
            'date': date,
            'points': 10,
            'icon': 'up',
          });
        } else if (status == 'failed') {
          activities.add({
            'type': 'failed',
            'title': 'Failed "$habitName"',
            'subtitle': _formatTime(date),
            'date': date,
            'points': 0,
            'icon': 'down',
          });
        } else if (status == 'skipped') {
          activities.add({
            'type': 'skipped',
            'title': 'Skipped "$habitName"',
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
      final achievementsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .orderBy('earnedAt', descending: true)
          .get();
      
      final achievements = <Map<String, dynamic>>[];
      
      for (final doc in achievementsSnapshot.docs) {
        final data = doc.data();
        achievements.add({
          'id': doc.id,
          'title': data['title'] ?? 'Achievement',
          'description': data['description'] ?? '',
          'icon': data['icon'] ?? '🏆',
          'earnedAt': (data['earnedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        });
      }
      
      // If no achievements, add default ones
      if (achievements.isEmpty) {
        achievements.addAll([
          {
            'id': '1',
            'title': 'Best Runner!',
            'description': 'Completed running habit 30 days in a row',
            'icon': '🏃',
            'earnedAt': DateTime.now().subtract(const Duration(days: 30)),
          },
          {
            'id': '2',
            'title': 'Best of the month!',
            'description': 'Top performer this month',
            'icon': '🥇',
            'earnedAt': DateTime.now().subtract(const Duration(days: 2)),
          },
        ]);
      }
      
      setState(() {
        _achievements = achievements;
      });
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
      dayText = 'Today';
    } else if (dateDay.isAtSameMomentAs(yesterday)) {
      dayText = 'Yesterday';
    } else {
      dayText = DateFormat('d MMM').format(date);
    }
    
    final timeText = DateFormat('h:mm a').format(date);
    return '$dayText, $timeText';
  }
  
  String _formatRelativeTime(DateTime date) {
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
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
                  _buildFriendsTab(),
                  _buildAchievementsTab(),
                ],
              ),
            ),
          ],
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
          const Text(
            'Your Profile',
            style: TextStyle(
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
                // Navigate to settings
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
              child: _avatarUrl != null
                  ? Image.network(
                      _avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(),
                    )
                  : _buildDefaultAvatar(),
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
                        '$_points Points',
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
        tabs: const [
          Tab(text: 'Activity'),
          Tab(text: 'Friends'),
          Tab(text: 'Achievements'),
        ],
      ),
    );
  }
  
  String _getActivityFilterText() {
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
                            'Today',
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
                            'Last week',
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
                            'Last month',
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
                  ? _buildEmptyState('No activity yet', 'Start completing habits to see your activity!')
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
  
  Widget _buildFriendsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_friendsCount Friends',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE8EDF5)),
                    ),
                    child: IconButton(
                      onPressed: () {
                        // Add friend
                      },
                      icon: const Icon(
                        Icons.add,
                        color: Colors.black54,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE8EDF5)),
                    ),
                    child: IconButton(
                      onPressed: () {
                        // Edit
                      },
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.black54,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _friends.isEmpty
                  ? _buildEmptyState('No friends yet', 'Add friends to compete with them!')
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
                        itemCount: _friends.length,
                        itemBuilder: (context, index) {
                          return _buildFriendItem(_friends[index]);
                        },
                      ),
                    ),
        ),
      ],
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
              child: friend['avatarUrl'] != null
                  ? Image.network(
                      friend['avatarUrl'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultFriendAvatar(friend['name']),
                    )
                  : _buildDefaultFriendAvatar(friend['name']),
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
                  '${friend['points']} Points',
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
                '${_achievements.length} Achievements',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _achievements.isEmpty
                  ? _buildEmptyState('No achievements yet', 'Complete habits to unlock achievements!')
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
                      ),
                    ),
        ),
      ],
    );
  }
  
  Widget _buildAchievementItem(Map<String, dynamic> achievement) {
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
                achievement['icon'] as String,
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
                  achievement['title'] as String,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatRelativeTime(achievement['earnedAt'] as DateTime),
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
