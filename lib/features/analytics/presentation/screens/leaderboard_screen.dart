import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/features/analytics/presentation/screens/user_profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('points', descending: true)
          .limit(100)
          .get();

      final usersList = usersSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'firstName': data['firstName'] ?? '',
          'lastName': data['lastName'] ?? '',
          'avatarUrl': data['avatarUrl'],
          'points': data['points'] ?? 0,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _users = usersList;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[LEADERBOARD ERROR] Failed to load users: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
          'Лидерборд',
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
          : _users.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) => _buildUserTile(index),
                ),
    );
  }

  Widget _buildUserTile(int index) {
    final user = _users[index];
    final points = user['points'] as int? ?? 0;
    final firstName = user['firstName'] as String? ?? '';
    final lastName = user['lastName'] as String? ?? '';
    final avatarUrl = user['avatarUrl'] as String?;
    final userId = user['id'] as String? ?? '';

    final displayName = '$firstName $lastName'.trim().isNotEmpty
        ? '$firstName $lastName'
        : 'User';

    // Определяем стиль для топ-3
    bool isTop3 = index < 3;
    bool isFirst = index == 0;
    bool isSecond = index == 1;
    bool isThird = index == 2;

    IconData? rankIcon;
    Color? rankIconColor;

    if (isFirst) {
      rankIcon = Icons.emoji_events;
      rankIconColor = AppColors.orange;
    } else if (isSecond) {
      rankIcon = Icons.emoji_events;
      rankIconColor = AppColors.black40;
    } else if (isThird) {
      rankIcon = Icons.emoji_events;
      rankIconColor = const Color(0xFFCD7F32); // Bronze
    } else {
      rankIcon = Icons.numbers;
      rankIconColor = AppColors.black60;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(
              userId: userId,
              userName: displayName,
              points: points,
              avatarUrl: avatarUrl,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isTop3 ? AppColors.blue20 : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ранк
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isTop3 ? AppColors.blue10 : AppColors.black10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    rankIcon,
                    color: rankIconColor,
                    size: isFirst ? 24 : 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Аватар
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.blue20,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? const Icon(Icons.person, color: AppColors.blue100, size: 24)
                    : null,
              ),
              const SizedBox(width: 12),

              // Имя
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: AppFonts.bodyTitleMedium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Пользователь',
                      style: AppFonts.bodyAlternative.copyWith(
                        fontSize: 12,
                        color: AppColors.black40,
                      ),
                    ),
                  ],
                ),
              ),

              // Очки
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.orange10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      color: AppColors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$points',
                      style: AppFonts.bodyAlternative.copyWith(
                        color: AppColors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.black20,
          ),
          const SizedBox(height: 16),
          Text(
            'Пока нет пользователей',
            style: AppFonts.bodyTitleMedium.copyWith(
              color: AppColors.black40,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Начните выполнять привычки чтобы попасть в лидерборд',
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
}
