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
  Map<String, HabitLogModel> _habitLogs = {};
  Map<String, String> _challengeNames = {}; // challengeId -> name
  Map<String, Map<String, dynamic>> _challengesData = {}; // challengeId -> full challenge data
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

      // Разделяем на обычные и челлендж-привычки
      final userHabits = allHabits.where((h) => h.challengeId == null || h.challengeId!.isEmpty).toList();
      final challengeHabits = allHabits.where((h) => h.challengeId != null && h.challengeId!.isNotEmpty).toList();

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

      // Загружаем логи для выбранной даты
      final effectiveDate = widget.selectedDate ?? DateTime.now();
      final logs = await _habitRepository.getHabitLogsForDate(user.uid, effectiveDate);

      final logsMap = <String, HabitLogModel>{};
      for (final log in logs) {
        logsMap[log.habitId] = log;
      }

      if (mounted) {
        setState(() {
          _userHabits = userHabits;
          _challengeHabits = challengeHabits;
          _habitLogs = logsMap;
          _challengeNames = challengeNames;
          _challengesData = challengesData;
          _isLoading = false;
        });
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
