import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/core/widgets/habits_widget.dart';
import 'package:routiner/features/habits/data/models/habit_model.dart';
import 'package:routiner/features/habits/data/models/habit_log_model.dart';
import 'package:routiner/features/habits/data/repositories/habit_repository.dart';
import 'package:routiner/features/habits/presentation/screens/habit_detail_screen.dart';
import 'package:routiner/l10n/app_localizations.dart';

/// Виджет для отображения привычек челленджа
/// Загружает привычки напрямую из habits коллекции по challengeId
class ChallengeHabitsWidget extends StatefulWidget {
  final String challengeId;
  final Color challengeColor;
  final DateTime? selectedDate; // Дата для которой показывать прогресс (null = сегодня)
  final VoidCallback? onProgressChanged; // Callback при изменении прогресса
  final AppLocalizations l10n;

  const ChallengeHabitsWidget({
    super.key,
    required this.challengeId,
    required this.challengeColor,
    this.selectedDate,
    this.onProgressChanged,
    required this.l10n,
  });

  @override
  State<ChallengeHabitsWidget> createState() => _ChallengeHabitsWidgetState();
}

class _ChallengeHabitsWidgetState extends State<ChallengeHabitsWidget> {
  final HabitRepository _habitRepository = HabitRepository();
  List<HabitModel> _habits = [];
  Map<String, HabitLogModel?> _habitLogs = {}; // habitId -> log for today
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChallengeHabits();
  }

  @override
  void didUpdateWidget(covariant ChallengeHabitsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Обновляем если изменился challengeId или selectedDate
    if (oldWidget.challengeId != widget.challengeId ||
        oldWidget.selectedDate != widget.selectedDate) {
      _loadChallengeHabits();
    }
  }
  
  /// Получить эффективную дату (выбранную или сегодня)
  DateTime get _effectiveDate => widget.selectedDate ?? DateTime.now();

  /// Загружаем привычки из habits коллекции где challengeId == widget.challengeId
  Future<void> _loadChallengeHabits() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // Получаем все привычки пользователя
      final allHabits = await _habitRepository.getUserHabitsFromServer(userId);
      
      // Фильтруем только привычки этого челленджа
      final challengeHabits = allHabits
          .where((h) => h.challengeId == widget.challengeId)
          .toList();
      
      // Загружаем логи для каждой привычки на выбранную дату
      final targetDate = _effectiveDate;
      final logs = <String, HabitLogModel?>{};
      
      for (final habit in challengeHabits) {
        if (habit.id != null) {
          final logDoc = await _habitRepository.getHabitLogForDate(habit.id!, targetDate);
          logs[habit.id!] = logDoc;
        }
      }

      if (mounted) {
        setState(() {
          _habits = challengeHabits;
          _habitLogs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[ChallengeHabitsWidget] Error loading habits: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onHabitAction(HabitModel habit, HabitAction action) async {
    if (habit.id == null) return;
    final habitId = habit.id!;
    
    // Используем выбранную дату для действий
    final targetDate = _effectiveDate;
    
    try {
      switch (action) {
        case HabitAction.done:
          // Отметить как выполненное
          await _habitRepository.updateHabitStatus(
            habitId,
            targetDate,
            HabitStatus.completed,
            value: habit.targetValue,
          );
          break;
        case HabitAction.add:
          // Добавить шаг
          await _habitRepository.incrementHabitProgress(
            habitId,
            targetDate,
            habit.incrementStep,
          );
          break;
        case HabitAction.skip:
          // Пропустить
          await _habitRepository.updateHabitStatus(
            habitId,
            targetDate,
            HabitStatus.skipped,
          );
          break;
        case HabitAction.fall:
          // Провалить
          await _habitRepository.updateHabitStatus(
            habitId,
            targetDate,
            HabitStatus.failed,
          );
          break;
      }
      
      // Обновляем UI
      await _loadChallengeHabits();
      
      // Уведомляем родителя об изменении прогресса
      if (mounted && widget.onProgressChanged != null) {
        widget.onProgressChanged!();
      }
    } catch (e) {
      print('[ChallengeHabitsWidget] Error on habit action: $e');
    }
  }

  String _getLocalizedHabitNameFromChallenge(String habitName) {
    switch (habitName) {
      case 'Drink water':
        return widget.l10n.translate('drinkWater');
      case 'Daily workout':
        return widget.l10n.translate('dailyWorkout');
      case 'Take 8K steps':
        return widget.l10n.translate('take8KSteps');
      case 'Meditate':
        return widget.l10n.translate('meditate');
      case 'Morning stretch':
        return widget.l10n.translate('morningStretch');
      case 'Read book':
        return widget.l10n.translate('readBook');
      case 'Eat vegetables':
        return widget.l10n.translate('eatVegetables');
      case 'Cook at home':
        return widget.l10n.translate('cookAtHome');
      case 'No phone 1h before bed':
        return widget.l10n.translate('noPhone1hBeforeBed');
      case 'Read instead':
        return widget.l10n.translate('readInstead');
      case 'No sugar':
        return widget.l10n.translate('noSugar');
      case 'Max 1 coffee':
        return widget.l10n.translate('max1Coffee');
      case 'Drink herbal tea':
        return widget.l10n.translate('drinkHerbalTea');
      case 'Complete 3 priorities':
        return widget.l10n.translate('complete3Priorities');
      case 'No social media at work':
        return widget.l10n.translate('noSocialMediaAtWork');
      case 'Max 1h TV/Netflix':
        return widget.l10n.translate('max1hTvNetflix');
      case 'Go for a walk':
        return widget.l10n.translate('goForAWalk');
      case 'cycling':
        return widget.l10n.translate('cycling');
      case 'Cycling':
        return widget.l10n.translate('cycling');
      default:
        return habitName;
    }
  }

  String _getLocalizedUnit(String unit) {
    switch (unit) {
      case 'glasses':
        return widget.l10n.translate('glasses');
      case 'min':
        return widget.l10n.translate('min');
      case 'steps':
        return widget.l10n.translate('steps');
      case 'servings':
        return widget.l10n.translate('servings');
      case 'meal':
        return widget.l10n.translate('meal');
      case 'day':
        return widget.l10n.translate('day');
      case 'pages':
        return widget.l10n.translate('pages');
      case 'cups':
        return widget.l10n.translate('cups');
      case 'tasks':
        return widget.l10n.translate('tasks');
      case 'hour':
        return widget.l10n.translate('hour');
      default:
        return unit;
    }
  }

  String _getLocalizedChallengeName(String challengeId) {
    switch (challengeId) {
      case '7_day_water':
        return widget.l10n.translate('sevenDayWaterChallenge');
      case '21_day_fitness':
        return widget.l10n.translate('twentyOneDayFitnessKickstart');
      case 'morning_routine':
        return widget.l10n.translate('perfectMorningRoutine');
      case 'read_daily':
        return widget.l10n.translate('dailyReadingHabit');
      case 'eat_healthy':
        return widget.l10n.translate('healthyEatingWeek');
      case 'no_phone_before_bed':
        return widget.l10n.translate('betterSleepNoPhoneBeforeBed');
      case 'no_sugar_week':
        return widget.l10n.translate('noSugarWeek');
      case 'reduce_caffeine':
        return widget.l10n.translate('reduceCaffeineIntake');
      case 'no_procrastination':
        return widget.l10n.translate('beatProcrastination');
      case 'less_tv':
        return widget.l10n.translate('lessScreenTime');
      default:
        return '';
    }
  }

  List<Habit> _convertToHabits() {
    return _habits.map((habit) {
      final log = _habitLogs[habit.id];
      final currentProgress = log?.value ?? 0;
      final status = log?.status ?? HabitStatus.pending;
      
      // Формируем subtitle как на главном экране: текущий/целевой прогресс
      final subtitle = status == HabitStatus.completed 
          ? '${habit.targetValue}/${habit.targetValue} ${_getLocalizedUnit(habit.targetUnit)}'
          : '$currentProgress/${habit.targetValue} ${_getLocalizedUnit(habit.targetUnit)}';
      
      return Habit(
        id: habit.id ?? '',
        title: _getLocalizedHabitNameFromChallenge(habit.name),
        subtitle: subtitle,
        isChallenge: true, // Всегда true для привычек челленджа
        challengeId: widget.challengeId,
        challengeName: _getLocalizedChallengeName(widget.challengeId), // Локализованное имя челленджа
        friendsCount: 0,
        currentProgress: currentProgress,
        targetProgress: habit.targetValue,
        emoji: habit.emoji,
        color: widget.challengeColor,
        streak: 0,
        habitType: habit.habitType,
        status: status,
        incrementStep: habit.incrementStep,
        onViewPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => HabitDetailScreen(
                habit: habit,
                challengeId: widget.challengeId,
                challengeName: _getLocalizedChallengeName(widget.challengeId), // Локализованное имя челленджа
              ),
            ),
          );
        },
        onDonePressed: () => _onHabitAction(habit, HabitAction.done),
        onAddPressed: (value) => _onHabitAction(habit, HabitAction.add),
        onSkipPressed: () => _onHabitAction(habit, HabitAction.skip),
        onFallPressed: () => _onHabitAction(habit, HabitAction.fall),
        l10n: widget.l10n,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 48,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              widget.l10n.translate('noTasksYet'),
              style: AppFonts.bodyTitleMedium.copyWith(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return HabitsWidget(
      habits: _convertToHabits(),
      isDarkBackground: true, // Белые цвета для темного фона челленджа
      l10n: widget.l10n,
    );
  }
}

enum HabitAction {
  done,
  add,
  skip,
  fall,
}
