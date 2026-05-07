import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/core/constants/default_habits.dart';
import 'package:routiner/features/habits/data/models/habit_model.dart';
import 'package:routiner/features/habits/data/models/habit_log_model.dart';
import 'package:routiner/features/habits/data/repositories/habit_repository.dart';
import 'package:routiner/features/create_habit/presentation/screens/custom_habit_screen.dart';
import 'package:routiner/features/habits/presentation/screens/habit_detail_screen.dart';
import 'package:routiner/features/challenges/domain/services/challenges_service.dart';
import 'package:routiner/features/challenges/presentation/screens/challenge_detail_screen.dart';
import 'package:routiner/features/clubs/presentation/screens/club_detail_screen.dart';

/// Экран списка всех привычек с горизонтальными списками как в Explore
class HabitsListScreen extends StatefulWidget {
  final DateTime? selectedDate;

  const HabitsListScreen({
    super.key,
    this.selectedDate,
  });

  @override
  State<HabitsListScreen> createState() => _HabitsListScreenState();
}

class _HabitsListScreenState extends State<HabitsListScreen> {
  final HabitRepository _habitRepository = HabitRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<HabitModel> _userHabits = [];
  List<HabitModel> _challengeHabits = [];
  List<HabitModel> _clubHabits = [];
  Map<String, HabitLogModel> _habitLogs = {};
  Map<String, String> _challengeNames = {}; // challengeId -> name
  Map<String, Map<String, dynamic>> _challengesData = {}; // challengeId -> full challenge data
  Map<String, Map<String, dynamic>> _clubsData = {}; // clubId -> full club data
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Загружаем все привычки пользователя
      final habitsStream = _habitRepository.getUserHabits(user.uid);
      final allHabits = await habitsStream.first;

      // Разделяем на обычные, челлендж-привычки и клубные привычки
      final userHabits = allHabits.where((h) => h.challengeId == null || h.challengeId!.isEmpty).toList();
      final challengeHabits = allHabits.where((h) => h.challengeId != null && !h.challengeId!.startsWith('club_')).toList();
      final clubHabits = allHabits.where((h) => h.challengeId != null && h.challengeId!.startsWith('club_')).toList();

      // Отладочная информация
      print('[HABITS LIST] Total habits: ${allHabits.length}');
      print('[HABITS LIST] User habits: ${userHabits.length}');
      print('[HABITS LIST] Challenge habits: ${challengeHabits.length}');
      print('[HABITS LIST] Club habits: ${clubHabits.length}');
      for (final clubHabit in clubHabits) {
        print('[HABITS LIST] Club habit: ${clubHabit.name} - ${clubHabit.challengeId}');
      }

      // Загружаем челленджи для получения их данных
      final challengesService = ChallengesService();
      final joinedChallenges = await challengesService.getJoinedChallenges();
      final challengeNames = <String, String>{};
      final challengesData = <String, Map<String, dynamic>>{};
      for (final challenge in joinedChallenges) {
        final id = challenge['id'] as String? ?? challenge['title'] as String;
        final title = challenge['title'] as String;
        challengeNames[id] = title;
        challengesData[id] = challenge;
      }

      // Загружаем данные клубов
      final clubsData = <String, Map<String, dynamic>>{};
      final allClubs = [
        {
          'id': 'cat_lovers',
          'name': 'Cat Lovers',
          'description': 'Build daily habits while celebrating our feline friends',
          'emoji': '🐱',
          'members': '500+',
          'color': const Color(0xFFFF6B6B),
        },
        {
          'id': 'book_worms',
          'name': 'Book Worms',
          'description': 'Cultivate reading habits and expand your knowledge daily',
          'emoji': '📚',
          'members': '1.2k',
          'color': const Color(0xFF4ECDC4),
        },
        {
          'id': 'runners',
          'name': 'Runners',
          'description': 'Build consistent running habits and achieve your fitness goals',
          'emoji': '🏃',
          'members': '800+',
          'color': const Color(0xFF95E1D3),
        },
        {
          'id': 'yoga_life',
          'name': 'Yoga Life',
          'description': 'Transform your life through daily yoga and mindfulness practices',
          'emoji': '🧘',
          'members': '2k',
          'color': const Color(0xFFA8E6CF),
        },
        {
          'id': 'meditation',
          'name': 'Meditation',
          'description': 'Find inner peace and build mental clarity through meditation',
          'emoji': '🧠',
          'members': '3k+',
          'color': const Color(0xFFC7CEEA),
        },
        {
          'id': 'fitness_gurus',
          'name': 'Fitness Gurus',
          'description': 'Build strength and endurance with daily workout routines',
          'emoji': '💪',
          'members': '1.5k',
          'color': const Color(0xFFFFD93D),
        },
        {
          'id': 'creative_minds',
          'name': 'Creative Minds',
          'description': 'Nurture your creativity with daily artistic practices',
          'emoji': '🎨',
          'members': '750+',
          'color': const Color(0xFFE8B4F8),
        },
        {
          'id': 'eco_warriors',
          'name': 'Eco Warriors',
          'description': 'Build sustainable habits and protect our planet daily',
          'emoji': '🌱',
          'members': '900+',
          'color': const Color(0xFF90EE90),
        },
      ];
      
      for (final club in allClubs) {
        final clubId = club['id'] as String;
        clubsData[clubId] = club;
        print('[HABITS LIST] Added club data: $clubId -> ${club['name']}');
      }

      // Загружаем логи для выбранной даты
      final effectiveDate = widget.selectedDate ?? DateTime.now();
      final logs = await _habitRepository.getHabitLogsForDate(user.uid, effectiveDate);

      final logsMap = <String, HabitLogModel>{};
      for (final log in logs) {
        logsMap[log.habitId] = log;
      }

      if (mounted) {
        print('[HABITS LIST] Setting state with club habits: ${clubHabits.length}');
        setState(() {
          _userHabits = userHabits;
          _challengeHabits = challengeHabits;
          _clubHabits = clubHabits;
          _habitLogs = logsMap;
          _challengeNames = challengeNames;
          _challengesData = challengesData;
          _clubsData = clubsData;
          _isLoading = false;
        });
        print('[HABITS LIST] State updated, _clubHabits.length: ${_clubHabits.length}');
      }
    } catch (e) {
      print('[HABITS LIST ERROR] $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header как в ExploreScreen
          Container(
            width: double.infinity,
            color: Colors.white,
            child: SafeArea(
              bottom: false,
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
                          'Habits',
                          style: AppFonts.headlineH5,
                        ),
                        const SizedBox(width: 48),
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
              onRefresh: _loadHabits,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Смешиваем популярные привычки: хорошие + 2 плохих для разнообразия
    final popularHabits = [
      ...DefaultHabits.goodHabits.take(6),
      ...DefaultHabits.badHabits.take(2),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // === МОИ ПРИВЫЧКИ (простой список) ===
        if (_userHabits.isNotEmpty) ...[
          _buildSectionHeader('Your Habits'),
          const SizedBox(height: 12),
          ..._userHabits.map((habit) => _buildUserHabitCard(habit)).toList(),
          const SizedBox(height: 32),
        ],

        // === ПРИВЫЧКИ ЧЕЛЛЕНДЖА (сгруппированы по челленджам) ===
        ..._buildChallengeSections(),

        // === ПРИВЫЧКИ КЛУБОВ (сгруппированы по клубам) ===
        ..._buildClubSections(),

        // === ПОПУЛЯРНЫЕ (горизонтальный список со смешанными привычками) ===
        _buildHorizontalSection(
          title: 'Popular',
          habits: popularHabits,
          showViewAll: false,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onTap}) {
    final content = Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppFonts.bodyTitleMedium.copyWith(
                color: AppColors.black100,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.black60,
              size: 18,
            ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent,
        child: content,
      );
    }

    return content;
  }

  /// Группирует challenge-привычки по челленджам и возвращает виджеты секций
  List<Widget> _buildChallengeSections() {
    if (_challengeHabits.isEmpty) return [];

    // Группируем привычки по challengeId
    final Map<String, List<HabitModel>> groupedHabits = {};
    for (final habit in _challengeHabits) {
      final challengeId = habit.challengeId ?? 'unknown';
      groupedHabits.putIfAbsent(challengeId, () => []);
      groupedHabits[challengeId]!.add(habit);
    }

    final List<Widget> sections = [];
    groupedHabits.forEach((challengeId, habits) {
      final challengeName = _challengeNames[challengeId] ?? 'Challenge';
      final challenge = _challengesData[challengeId];

      sections.addAll([
        _buildSectionHeader(
          challengeName,
          onTap: challenge != null
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChallengeDetailScreen(
                        challenge: challenge,
                        onJoinChanged: () {
                          // Обновляем при изменении
                          _loadHabits();
                        },
                      ),
                    ),
                  );
                }
              : null,
        ),
        const SizedBox(height: 12),
        ...habits.map((habit) => _buildChallengeHabitCard(habit, challengeName)).toList(),
        const SizedBox(height: 24),
      ]);
    });

    return sections;
  }

  /// Группирует клубные привычки по клубам и возвращает виджеты секций
  List<Widget> _buildClubSections() {
    print('[HABITS LIST] _buildClubSections() called, _clubHabits.length: ${_clubHabits.length}');
    if (_clubHabits.isEmpty) {
      print('[HABITS LIST] No club habits found, returning empty list');
      return [];
    }

    // Группируем привычки по clubId (извлекаем из challengeId)
    final Map<String, List<HabitModel>> groupedHabits = {};
    print('[HABITS LIST] Processing ${_clubHabits.length} club habits:');
    for (final habit in _clubHabits) {
      final challengeId = habit.challengeId ?? '';
      final clubId = challengeId.startsWith('club_') ? challengeId.substring(5) : 'unknown';
      print('[HABITS LIST] Club habit: ${habit.name}, challengeId: $challengeId, extracted clubId: $clubId');
      groupedHabits.putIfAbsent(clubId, () => []);
      groupedHabits[clubId]!.add(habit);
    }

    print('[HABITS LIST] Available clubs data: ${_clubsData.keys}');
    final List<Widget> sections = [];
    groupedHabits.forEach((clubId, habits) {
      print('[HABITS LIST] Looking for club with ID: $clubId');
      final club = _clubsData[clubId];
      if (club == null) {
        print('[HABITS LIST] Club not found for ID: $clubId');
        return;
      }

      final clubName = club['name'] as String? ?? 'Club';
      print('[HABITS LIST] Found club: $clubName with ${habits.length} habits');

      sections.addAll([
        _buildSectionHeader(
          clubName,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  // Импортируем ClubDetailScreen
                  return ClubDetailScreen(club: club);
                },
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        ...habits.map((habit) => _buildClubHabitCard(habit, clubName)).toList(),
        const SizedBox(height: 24),
      ]);
    });

    return sections;
  }

  /// Карточка привычки клуба (вертикальная с градиентом)
  Widget _buildClubHabitCard(HabitModel habit, String? clubName) {
    final habitId = habit.id?.isNotEmpty == true ? habit.id : null;
    final dayLog = habitId != null ? _habitLogs[habitId] : null;
    final isCompleted = dayLog?.isCompleted ?? false;
    final targetValue = habit.targetValue > 0 ? habit.targetValue : 1;
    final currentProgress = isCompleted ? targetValue : ((dayLog?.value ?? 0) > 0 ? dayLog!.value! : 0);
    final progressPercent = targetValue > 0
        ? (currentProgress / targetValue).clamp(0.0, 1.0)
        : 0.0;
    final targetUnit = habit.targetUnit.isNotEmpty ? habit.targetUnit : 'times';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => HabitDetailScreen(
              habit: habit,
              challengeId: habit.challengeId,
              challengeName: clubName,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF9C27B0), Color(0xFF673AB7)], // Фиолетовый градиент для клубов
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Иконка
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  habit.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Информация
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$currentProgress/$targetValue $targetUnit',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'CLUBS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Прогресс бар
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progressPercent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Карточка привычки пользователя (вертикальная цветная)
  Widget _buildUserHabitCard(HabitModel habit) {
    final habitId = habit.id?.isNotEmpty == true ? habit.id : null;
    final dayLog = habitId != null ? _habitLogs[habitId] : null;
    final isCompleted = dayLog?.isCompleted ?? false;
    final currentProgress = isCompleted ? (habit.targetValue > 0 ? habit.targetValue : 1) : ((dayLog?.value ?? 0) > 0 ? dayLog!.value! : 0);
    final targetValue = habit.targetValue > 0 ? habit.targetValue : 1;
    final progressPercent = targetValue > 0
        ? (currentProgress / targetValue).clamp(0.0, 1.0)
        : 0.0;
    final targetUnit = habit.targetUnit.isNotEmpty ? habit.targetUnit : 'times';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => HabitDetailScreen(
              habit: habit,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: habit.colorValue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Иконка в белом квадрате
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  habit.emoji,
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
                    habit.name,
                    style: AppFonts.bodyTitleMedium.copyWith(
                      color: AppColors.black100,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$currentProgress/$targetValue $targetUnit',
                    style: AppFonts.bodyAlternative.copyWith(
                      color: AppColors.black100,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Прогресс бар
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progressPercent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Карточка привычки челленджа (вертикальная с градиентом)
  Widget _buildChallengeHabitCard(HabitModel habit, String? challengeName) {
    final habitId = habit.id?.isNotEmpty == true ? habit.id : null;
    final dayLog = habitId != null ? _habitLogs[habitId] : null;
    final isCompleted = dayLog?.isCompleted ?? false;
    final targetValue = habit.targetValue > 0 ? habit.targetValue : 1;
    final currentProgress = isCompleted ? targetValue : ((dayLog?.value ?? 0) > 0 ? dayLog!.value! : 0);
    final progressPercent = targetValue > 0
        ? (currentProgress / targetValue).clamp(0.0, 1.0)
        : 0.0;
    final targetUnit = habit.targetUnit.isNotEmpty ? habit.targetUnit : 'times';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => HabitDetailScreen(
              habit: habit,
              challengeId: habit.challengeId,
              challengeName: challengeName,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.purple, AppColors.blue],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Иконка
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  habit.emoji,
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
                    habit.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$currentProgress/$targetValue $targetUnit',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Прогресс бар
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progressPercent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Горизонтальная секция как в ExploreScreen
  Widget _buildHorizontalSection({
    required String title,
    required List<DefaultHabit> habits,
    bool showViewAll = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок секции
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppFonts.bodyTitleMedium.copyWith(
                  color: AppColors.black100,
                ),
              ),
              if (showViewAll)
                GestureDetector(
                  onTap: () {
                    print('VIEW ALL $title pressed');
                  },
                  child: Text(
                    'VIEW ALL',
                    style: AppFonts.bodyAlternative.copyWith(
                      color: AppColors.blue100,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Горизонтальный список карточек привычек
        SizedBox(
          height: 104,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 24),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => HabitDetailScreen(
                        defaultHabit: habit,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 94,
                  height: 104,
                  margin: EdgeInsets.only(
                    right: index < habits.length - 1 ? 12 : 24,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: habit.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Верхняя часть с иконкой
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                habit.emoji,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Название привычки
                      Text(
                        habit.name,
                        style: AppFonts.bodyTitleMedium.copyWith(
                          color: AppColors.black100,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Подпись
                      Text(
                        habit.subtitle,
                        style: AppFonts.bodyAlternative.copyWith(
                          fontSize: 10,
                          color: AppColors.black60,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  void _showHabitOptions(HabitModel habit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              habit.name,
              style: AppFonts.bodyTitleMedium.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              icon: Icons.check_circle,
              label: 'Mark as Done',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                _updateHabitStatus(habit.id!, HabitStatus.completed);
              },
            ),
            _buildActionButton(
              icon: Icons.cancel,
              label: 'Mark as Failed',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _updateHabitStatus(habit.id!, HabitStatus.failed);
              },
            ),
            _buildActionButton(
              icon: Icons.skip_next,
              label: 'Skip Today',
              color: AppColors.black40,
              onTap: () {
                Navigator.pop(context);
                _updateHabitStatus(habit.id!, HabitStatus.skipped);
              },
            ),
            _buildActionButton(
              icon: Icons.edit,
              label: 'Edit Habit',
              color: AppColors.blue100,
              onTap: () {
                Navigator.pop(context);
                _editHabit(habit);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: AppFonts.bodyMedium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateHabitStatus(String habitId, HabitStatus status) async {
    try {
      final effectiveDate = widget.selectedDate ?? DateTime.now();
      final log = await _habitRepository.updateHabitStatus(habitId, effectiveDate, status);
      setState(() {
        _habitLogs[habitId] = log;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    }
  }

  Future<void> _addDefaultHabit(DefaultHabit defaultHabit) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final newHabit = HabitModel(
        userId: user.uid,
        name: defaultHabit.name,
        emoji: defaultHabit.emoji,
        color: HabitModel.colorToHex(defaultHabit.color),
        habitType: defaultHabit.isGoodHabit ? 'build' : 'quit',
        targetValue: defaultHabit.targetValue,
        targetUnit: defaultHabit.targetUnit,
        incrementStep: 1,
        frequency: defaultHabit.frequency,
        period: defaultHabit.period,
        isDefaultHabit: true,
        defaultHabitId: defaultHabit.id,
        motivation: defaultHabit.motivation,
      );

      await _habitRepository.createHabit(newHabit);
      _loadHabits();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${defaultHabit.name} added!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add: $e')),
      );
    }
  }

  void _editHabit(HabitModel habit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomHabitScreen(
          isBadHabit: habit.habitType == 'quit',
          moodEmoji: habit.emoji,
        ),
      ),
    ).then((_) => _loadHabits());
  }
}
