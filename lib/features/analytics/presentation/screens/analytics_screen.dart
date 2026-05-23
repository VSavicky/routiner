import 'dart:async';

import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/features/habits/data/repositories/habit_repository.dart';
import 'package:routiner/features/habits/data/models/habit_model.dart';
import 'package:routiner/features/habits/data/models/habit_log_model.dart';
import 'package:routiner/features/habits/domain/entities/habit_entity.dart';
import 'package:routiner/features/analytics/presentation/screens/leaderboard_screen.dart';
import 'package:routiner/l10n/app_localizations.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedTabIndex = 1; // 0 = Daily, 1 = Weekly, 2 = Monthly
  final HabitRepository _habitRepository = HabitRepository();

  // Функция локализации фильтров привычек
  String _getLocalizedFilter(String filter, BuildContext context) {
    switch (filter) {
      case 'All Habits':
        return context.l10n.translate('allHabits');
      case 'Good Habits':
        return context.l10n.translate('goodHabits');
      case 'Bad Habits':
        return context.l10n.translate('badHabits');
      default:
        return filter;
    }
  }

  // Функция для получения локализованного текста сравнения в зависимости от таба
  String _getLocalizedComparisonText(BuildContext context) {
    switch (_selectedTabIndex) {
      case 0: // Daily
        return context.l10n.translate('comparisonByDay');
      case 1: // Weekly
        return context.l10n.translate('comparisonByWeek');
      case 2: // Monthly
        return context.l10n.translate('comparisonByMonth');
      default:
        return context.l10n.translate('comparisonByWeek');
    }
  }

  // Функция для правильного склонения слова "привычки" в зависимости от числа
  String _getLocalizedHabitText(int count, BuildContext context) {
    if (count == 1) {
      return context.l10n.translate('habit');
    } else if (count >= 2 && count <= 4) {
      return context.l10n.translate('habits2');
    } else {
      return context.l10n.translate('habits5');
    }
  }

  // Данные из Firebase
  List<HabitModel> _habits = [];
  List<HabitLogModel> _allLogs = [];
  bool _isLoading = true;

  // Фильтр привычек
  String _selectedHabitFilter =
      'All Habits'; // 'All Habits', 'Good Habits', 'Bad Habits', или конкретное имя
  List<String> _habitFilterOptions = [
    'All Habits',
    'Good Habits',
    'Bad Habits',
  ];

  // Данные для статистики
  int _completedCount = 0;
  int _skippedCount = 0;
  int _failedCount = 0;
  int _pointsEarned = 0;
  int _bestStreak = 0;
  double _successRate = 0.0;
  int _completedHabitsCount =
      0; // Количество выполненных привычек для отображения

  // Данные для графика (последние 7 дней)
  List<int> _weeklyData = [0, 0, 0, 0, 0, 0, 0];
  List<int> _dailyData = [
    0,
    0,
    0,
    0,
    0,
    0,
  ]; // Данные за 24 часа (6 точек по 4 часа)
  List<int> _monthlyData = [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  ]; // Данные за месяц (7 периодов)

  // Дата для отображения
  DateTime _currentWeekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  );

  StreamSubscription<List<HabitModel>>? _habitsSubscription;
  StreamSubscription<List<HabitLogModel>>? _logsSubscription;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupLogsStream();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Обновляем данные каждый раз когда экран становится активным
    // Это гарантирует что новые настроения будут отображаться сразу
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  void _setupHabitsStream() {
    final userId = _habitRepository.currentUserId;
    if (userId == null) return;

    // Подписываемся на поток привычек для real-time обновлений
    _habitsSubscription = _habitRepository.getUserHabits(userId).listen((
      habits,
    ) {
      if (mounted) {
        setState(() {
          _habits = habits;
          // Обновляем фильтры с локализованными названиями
          final filterOptions = ['All Habits', 'Good Habits', 'Bad Habits'];
          for (var habit in habits) {
            // Создаем HabitEntity для получения локализованного названия
            final habitEntity = HabitEntity(
              id: habit.id ?? '',
              userId: habit.userId ?? '',
              name: habit.name,
              emoji: habit.emoji,
              days: [],
            );

            final localizedName = habitEntity.getLocalizedName(context.l10n);
            if (!filterOptions.contains(localizedName)) {
              filterOptions.add(localizedName);
            }
          }
          _habitFilterOptions = filterOptions;
          _calculateStats();
          _calculateChartData();
        });
      }
    });
  }

  @override
  void dispose() {
    _habitsSubscription?.cancel();
    _logsSubscription?.cancel();
    super.dispose();
  }

  void _setupLogsStream() {
    final userId = _habitRepository.currentUserId;
    if (userId == null) return;

    // Подписываемся на логи за последние 30 дней — обновляет данные в реальном времени
    final fromDate = DateTime.now().subtract(const Duration(days: 29));
    _logsSubscription = _habitRepository
        .getUserHabitLogsStream(userId, fromDate: fromDate)
        .listen((logs) {
          if (!mounted) return;
          setState(() {
            _allLogs = logs;
          });
          _calculateStats();
          _calculateChartData();
        });
  }

  Future<void> _loadData() async {
    final userId = _habitRepository.currentUserId;
    if (userId == null) return;

    try {
      setState(() => _isLoading = true);

      // Загружаем привычки и логи последовательно
      final habitsStream = _habitRepository.getUserHabits(userId);
      final logs = await _getLogsForLastDays(userId, 30);

      // Правильно обрабатываем Stream из привычек
      habitsStream.listen((habits) {
        setState(() {
          _habits = habits;
          _allLogs = logs;
          _isLoading = false;
        });

        // Рассчитываем статистику и данные для графиков
        _calculateStats();
        _calculateChartData();

        // Обновляем опции фильтра с конкретными привычками
        _updateHabitFilterOptions();
      });
    } catch (e) {
      print('[ANALYTICS ERROR] $e');
      setState(() => _isLoading = false);
    }
  }

  void _updateHabitFilterOptions() {
    // Начинаем с базовых опций
    final options = ['All Habits', 'Good Habits', 'Bad Habits'];

    // Добавляем каждую привычку отдельно с локализованными названиями
    for (final habit in _habits) {
      // Создаем HabitEntity для получения локализованного названия
      final habitEntity = HabitEntity(
        id: habit.id ?? '',
        userId: habit.userId ?? '',
        name: habit.name,
        emoji: habit.emoji,
        days: [],
      );

      final localizedName = habitEntity.getLocalizedName(context.l10n);
      if (!options.contains(localizedName)) {
        options.add(localizedName);
      }
    }

    setState(() {
      _habitFilterOptions = options;
    });
  }

  Future<List<HabitLogModel>> _getLogsForLastDays(
    String userId,
    int days,
  ) async {
    try {
      // Получаем логи за все дни периода ПАРАЛЛЕЛЬНО для скорости
      final futures = <Future<List<HabitLogModel>>>[];
      for (int i = 0; i < days; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        futures.add(_habitRepository.getHabitLogsForDate(userId, date));
      }

      final results = await Future.wait(futures);
      return results.expand((logs) => logs).toList();
    } catch (e) {
      print('[ANALYTICS ERROR] Failed to load logs: $e');
      return [];
    }
  }

  void _calculateStats() {
    final filteredLogs = _getFilteredLogs();

    if (_habits.isEmpty || filteredLogs.isEmpty) {
      setState(() {
        _successRate = 0.0;
        _completedCount = 0;
        _skippedCount = 0;
        _failedCount = 0;
        _pointsEarned = 0;
        _bestStreak = 0;
        _completedHabitsCount = 0;
      });
      return;
    }

    // Подсчитываем статусы
    int completed = 0;
    int skipped = 0;
    int failed = 0;
    int points = 0;

    for (var log in filteredLogs) {
      switch (log.status) {
        case HabitStatus.completed:
          completed++;
          points += 10; // 10 points за completed
          break;
        case HabitStatus.skipped:
          skipped++;
          break;
        case HabitStatus.failed:
          failed++;
          break;
        case HabitStatus.pending:
          break;
      }
    }

    // Считаем success rate (completed / total logs)
    final totalLogs = filteredLogs.length;
    final successRate = totalLogs > 0 ? (completed / totalLogs) * 100 : 0.0;

    // Считаем best streak
    int bestStreak = _calculateBestStreak();

    setState(() {
      _completedCount = completed;
      _skippedCount = skipped;
      _failedCount = failed;
      _pointsEarned = points;
      _successRate = successRate;
      _bestStreak = bestStreak;
      _completedHabitsCount = completed;
    });
  }

  int _calculateBestStreak() {
    // Получаем отфильтрованные привычки
    List<HabitModel> filteredHabits;
    if (_selectedHabitFilter == 'All Habits') {
      filteredHabits = _habits;
    } else if (_selectedHabitFilter == 'Good Habits') {
      filteredHabits = _habits.where((h) => h.habitType == 'build').toList();
    } else if (_selectedHabitFilter == 'Bad Habits') {
      filteredHabits = _habits.where((h) => h.habitType == 'quit').toList();
    } else {
      // Конкретная привычка
      filteredHabits = _habits
          .where((h) => h.name == _selectedHabitFilter)
          .toList();
    }

    if (filteredHabits.isEmpty) return 0;

    final filteredLogIds = _getFilteredLogs().map((l) => l.habitId).toSet();
    int bestStreak = 0;

    for (var habit in filteredHabits) {
      if (habit.id == null) continue;
      if (!filteredLogIds.contains(habit.id)) continue;

      int streak = 0;
      DateTime checkDate = DateTime.now();

      while (true) {
        final log = _allLogs.firstWhere(
          (l) =>
              l.habitId == habit.id &&
              l.date.year == checkDate.year &&
              l.date.month == checkDate.month &&
              l.date.day == checkDate.day,
          orElse: () => HabitLogModel(
            userId: '',
            habitId: '',
            date: checkDate,
            status: HabitStatus.pending,
          ),
        );

        if (log.status == HabitStatus.completed) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      if (streak > bestStreak) {
        bestStreak = streak;
      }
    }

    return bestStreak;
  }

  // Получить отфильтрованные логи по выбранной привычке и текущему периоду
  List<HabitLogModel> _getFilteredLogs() {
    // Сначала фильтруем по периоду
    final periodLogs = _getLogsForCurrentPeriod();

    // Затем фильтруем по привычке
    if (_selectedHabitFilter == 'All Habits') {
      return periodLogs;
    } else if (_selectedHabitFilter == 'Good Habits') {
      final goodHabitIds = _habits
          .where((h) => h.habitType == 'build')
          .map((h) => h.id)
          .where((id) => id != null)
          .cast<String>()
          .toSet();
      return periodLogs
          .where((log) => goodHabitIds.contains(log.habitId))
          .toList();
    } else if (_selectedHabitFilter == 'Bad Habits') {
      final badHabitIds = _habits
          .where((h) => h.habitType == 'quit')
          .map((h) => h.id)
          .where((id) => id != null)
          .cast<String>()
          .toSet();
      return periodLogs
          .where((log) => badHabitIds.contains(log.habitId))
          .toList();
    } else {
      // Конкретная привычка по имени
      final habit = _habits.firstWhere(
        (h) => h.name == _selectedHabitFilter,
        orElse: () => HabitModel(
          userId: '',
          name: '',
          emoji: '',
          color: '',
          habitType: 'build',
        ),
      );
      if (habit.id == null) return [];
      return periodLogs.where((log) => log.habitId == habit.id).toList();
    }
  }

  // Получить логи только за текущий выбранный период
  List<HabitLogModel> _getLogsForCurrentPeriod() {
    if (_selectedTabIndex == 0) {
      // Daily - только за выбранный день
      return _allLogs
          .where(
            (log) =>
                log.date.year == _currentWeekStart.year &&
                log.date.month == _currentWeekStart.month &&
                log.date.day == _currentWeekStart.day,
          )
          .toList();
    } else if (_selectedTabIndex == 1) {
      // Weekly - за выбранную неделю (7 дней)
      final weekEnd = _currentWeekStart.add(const Duration(days: 6));
      return _allLogs.where((log) {
        final logDate = DateTime(log.date.year, log.date.month, log.date.day);
        final start = DateTime(
          _currentWeekStart.year,
          _currentWeekStart.month,
          _currentWeekStart.day,
        );
        final end = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);
        return !logDate.isBefore(start) && !logDate.isAfter(end);
      }).toList();
    } else {
      // Monthly - за выбранный месяц
      return _allLogs
          .where(
            (log) =>
                log.date.year == _currentWeekStart.year &&
                log.date.month == _currentWeekStart.month,
          )
          .toList();
    }
  }

  void _calculateChartData() {
    switch (_selectedTabIndex) {
      case 0: // Daily
        _calculateDailyData();
        break;
      case 1: // Weekly
        _calculateWeeklyData();
        break;
      case 2: // Monthly
        _calculateMonthlyData();
        break;
    }
  }

  void _calculateDailyData() {
    // Считаем completed habits по часам за выбранный день (6 точек по 4 часа)
    final filteredLogs = _getFilteredLogs();
    final data = <int>[0, 0, 0, 0, 0, 0];
    final selectedDay = _currentWeekStart;

    print(
      '[ANALYTICS HABITS] Calculating daily data for ${selectedDay.month}/${selectedDay.day}',
    );
    print('[ANALYTICS HABITS] Found ${filteredLogs.length} filtered logs');

    for (var log in filteredLogs.where(
      (l) => l.status == HabitStatus.completed,
    )) {
      // Проверяем что лог относится к выбранному дню
      if (log.date.year == selectedDay.year &&
          log.date.month == selectedDay.month &&
          log.date.day == selectedDay.day) {
        final hour = log.date.hour;
        final slot = hour ~/ 4;
        if (slot < 6) {
          data[slot]++;
          print(
            '[ANALYTICS HABITS]   Completed habit at hour $hour -> slot $slot',
          );
        }
      }
    }

    setState(() {
      _dailyData = data;
    });
    print('[ANALYTICS HABITS] Daily data result: $data');
  }

  void _calculateWeeklyData() {
    // Считаем completed habits за каждый день выбранной недели
    final filteredLogs = _getFilteredLogs();
    final data = <int>[];

    print(
      '[ANALYTICS HABITS] Calculating weekly data for week starting ${_currentWeekStart.month}/${_currentWeekStart.day}',
    );

    for (int i = 0; i <= 6; i++) {
      final date = _currentWeekStart.add(Duration(days: i));
      final dayLogs = filteredLogs.where(
        (log) =>
            log.date.year == date.year &&
            log.date.month == date.month &&
            log.date.day == date.day &&
            log.status == HabitStatus.completed,
      );
      data.add(dayLogs.length);
      print(
        '[ANALYTICS HABITS] Day $i (${date.month}/${date.day}): ${dayLogs.length} completed habits',
      );
    }

    setState(() {
      _weeklyData = data;
    });
    print('[ANALYTICS HABITS] Weekly data result: $data');
  }

  void _calculateMonthlyData() {
    // Считаем completed habits за недели выбранного месяца (7 точек по ~4 дня)
    final filteredLogs = _getFilteredLogs();
    final data = <int>[0, 0, 0, 0, 0, 0, 0];

    // Определяем последний день месяца
    final lastDayOfMonth = DateTime(
      _currentWeekStart.month == 12
          ? _currentWeekStart.year + 1
          : _currentWeekStart.year,
      _currentWeekStart.month == 12 ? 1 : _currentWeekStart.month + 1,
      0,
    ).day;

    // Разбиваем месяц на 7 периодов (минимум 1 день на слот)
    final daysPerSlot = (lastDayOfMonth / 7).ceil().clamp(1, 31);

    print(
      '[ANALYTICS HABITS] Calculating monthly data for ${_currentWeekStart.month}/${_currentWeekStart.year}',
    );
    print(
      '[ANALYTICS HABITS] Month has $lastDayOfMonth days, $daysPerSlot days per slot',
    );

    for (var log in filteredLogs.where(
      (l) => l.status == HabitStatus.completed,
    )) {
      if (log.date.year == _currentWeekStart.year &&
          log.date.month == _currentWeekStart.month) {
        final day = log.date.day.clamp(1, lastDayOfMonth);
        final slot = ((day - 1) ~/ daysPerSlot).clamp(0, 6);
        data[slot]++;
        print('[ANALYTICS HABITS]   Completed habit on day $day -> slot $slot');
      }
    }

    setState(() {
      _monthlyData = data;
    });
    print('[ANALYTICS HABITS] Monthly data result: $data');
  }

  // Получить заголовок периода (This week / This month / Today)
  String _getPeriodTitle() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = DateTime(
      _currentWeekStart.year,
      _currentWeekStart.month,
      _currentWeekStart.day,
    );

    if (_selectedTabIndex == 0) {
      // Daily
      if (current.isAtSameMomentAs(today)) {
        return context.l10n.translate('today');
      } else if (current.isAtSameMomentAs(
        today.subtract(const Duration(days: 1)),
      )) {
        return context.l10n.translate('yesterday');
      } else {
        return context.l10n.translate('thisDay');
      }
    } else if (_selectedTabIndex == 1) {
      // Weekly
      if (_currentWeekStart.isAtSameMomentAs(
        today.subtract(Duration(days: today.weekday - 1)),
      )) {
        return context.l10n.translate('thisWeek');
      } else {
        return context.l10n.translate('thisWeek');
      }
    } else {
      // Monthly
      if (_currentWeekStart.month == now.month &&
          _currentWeekStart.year == now.year) {
        return context.l10n.translate('thisMonth');
      } else {
        return context.l10n.translate('thisMonth');
      }
    }
  }

  String _getWeekRangeText() {
    final endOfWeek = _currentWeekStart.add(const Duration(days: 6));

    // Локализованные месяцы
    final months = [
      context.l10n.translate('january'),
      context.l10n.translate('february'),
      context.l10n.translate('march'),
      context.l10n.translate('april'),
      context.l10n.translate('may'),
      context.l10n.translate('june'),
      context.l10n.translate('july'),
      context.l10n.translate('august'),
      context.l10n.translate('september'),
      context.l10n.translate('october'),
      context.l10n.translate('november'),
      context.l10n.translate('december'),
    ];

    final startMonth = months[_currentWeekStart.month - 1];
    final endMonth = months[endOfWeek.month - 1];

    if (_selectedTabIndex == 0) {
      // Daily view - show current date
      return '${months[_currentWeekStart.month - 1]} ${_currentWeekStart.day}';
    } else if (_selectedTabIndex == 2) {
      // Monthly view
      return '${months[_currentWeekStart.month - 1]} ${_currentWeekStart.year}';
    }

    if (_currentWeekStart.month == endOfWeek.month) {
      return '$startMonth ${_currentWeekStart.day} - ${endOfWeek.day}';
    } else {
      return '$startMonth ${_currentWeekStart.day} - $endMonth ${endOfWeek.day}';
    }
  }

  void _goToPreviousPeriod() {
    setState(() {
      if (_selectedTabIndex == 0) {
        // Daily - go to previous day
        _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 1));
      } else if (_selectedTabIndex == 2) {
        // Monthly - go to previous month
        _currentWeekStart = DateTime(
          _currentWeekStart.month == 1
              ? _currentWeekStart.year - 1
              : _currentWeekStart.year,
          _currentWeekStart.month == 1 ? 12 : _currentWeekStart.month - 1,
          1,
        );
      } else {
        // Weekly - go to previous week
        _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
      }
    });
    _updateDataForCurrentPeriod();
  }

  void _goToNextPeriod() {
    // Don't allow navigating to future dates beyond today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime nextPeriodStart;
    if (_selectedTabIndex == 0) {
      nextPeriodStart = _currentWeekStart.add(const Duration(days: 1));
    } else if (_selectedTabIndex == 2) {
      nextPeriodStart = DateTime(
        _currentWeekStart.month == 12
            ? _currentWeekStart.year + 1
            : _currentWeekStart.year,
        _currentWeekStart.month == 12 ? 1 : _currentWeekStart.month + 1,
        1,
      );
    } else {
      nextPeriodStart = _currentWeekStart.add(const Duration(days: 7));
    }

    // Don't go beyond today
    if (nextPeriodStart.isAfter(today)) {
      return;
    }

    setState(() {
      _currentWeekStart = nextPeriodStart;
    });
    _updateDataForCurrentPeriod();
  }

  // Быстрое обновление данных без перезагрузки из Firebase (используем кэш)
  void _updateDataForCurrentPeriod() {
    setState(() {
      _calculateStats();
      _calculateChartData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  // Обновляем все данные включая настроения
                  await _loadData();
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.l10n.translate('activity'),
                            style: AppFonts.bodyTitleMedium.copyWith(
                              color: AppColors.black100,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LeaderboardScreen(),
                                ),
                              );
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.blue10,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.people,
                                color: AppColors.blue100,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Tab Bar (Daily / Weekly / Monthly)
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.black10,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [
                            _buildTab(0, context.l10n.translate('daily')),
                            _buildTab(1, context.l10n.translate('weekly')),
                            _buildTab(2, context.l10n.translate('monthly')),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Date Navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getPeriodTitle(),
                                style: AppFonts.bodyTitleMedium.copyWith(
                                  color: AppColors.black100,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getWeekRangeText(),
                                style: AppFonts.bodyAlternative.copyWith(
                                  color: AppColors.black40,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _goToPreviousPeriod,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.black10,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.black10,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.chevron_left,
                                    color: AppColors.black60,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _goToNextPeriod,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.black10,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.black10,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.chevron_right,
                                    color: AppColors.black60,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // All Habits Summary Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.blue10Primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with dropdown
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.black10,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '👀',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getLocalizedFilter(
                                            _selectedHabitFilter,
                                            context,
                                          ),
                                          style: AppFonts.bodyTitleMedium
                                              .copyWith(
                                                color: AppColors.black100,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        Text(
                                          context.l10n.translate('summary'),
                                          style: AppFonts.bodyAlternative
                                              .copyWith(
                                                color: AppColors.black40,
                                                fontSize: 12,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: _showHabitFilterDropdown,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.black10,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: AppColors.black60,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Stats Grid
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.l10n
                                            .translate('successRate')
                                            .toUpperCase(),
                                        style: AppFonts.bodyAlternative
                                            .copyWith(
                                              color: AppColors.black40,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_successRate.toInt()}%',
                                        style: AppFonts.bodyTitleMedium
                                            .copyWith(
                                              color: AppColors.green,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.l10n
                                            .translate('completed')
                                            .toUpperCase(),
                                        style: AppFonts.bodyAlternative
                                            .copyWith(
                                              color: AppColors.black40,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$_completedCount',
                                        style: AppFonts.bodyTitleMedium
                                            .copyWith(
                                              color: AppColors.black100,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.l10n
                                            .translate('pointsEarned')
                                            .toUpperCase(),
                                        style: AppFonts.bodyAlternative
                                            .copyWith(
                                              color: AppColors.black40,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            width: 16,
                                            height: 16,
                                            decoration: const BoxDecoration(
                                              color: AppColors.orange,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.star,
                                                color: Colors.white,
                                                size: 10,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '$_pointsEarned',
                                            style: AppFonts.bodyTitleMedium
                                                .copyWith(
                                                  color: AppColors.orange,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.l10n
                                            .translate('bestStreakDay')
                                            .toUpperCase(),
                                        style: AppFonts.bodyAlternative
                                            .copyWith(
                                              color: AppColors.black40,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$_bestStreak',
                                        style: AppFonts.bodyTitleMedium
                                            .copyWith(
                                              color: AppColors.black100,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.l10n
                                            .translate('skipped')
                                            .toUpperCase(),
                                        style: AppFonts.bodyAlternative
                                            .copyWith(
                                              color: AppColors.black40,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$_skippedCount',
                                        style: AppFonts.bodyTitleMedium
                                            .copyWith(
                                              color: AppColors.black100,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.l10n
                                            .translate('failed')
                                            .toUpperCase(),
                                        style: AppFonts.bodyAlternative
                                            .copyWith(
                                              color: AppColors.black40,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$_failedCount',
                                        style: AppFonts.bodyTitleMedium
                                            .copyWith(
                                              color: AppColors.red,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Habits Chart Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.blue10Primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.black10,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.show_chart,
                                        color: AppColors.blue100,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.l10n.translate('habits'),
                                          style: AppFonts.bodyTitleMedium
                                              .copyWith(
                                                color: AppColors.black100,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        Text(
                                          _getLocalizedComparisonText(context),
                                          style: AppFonts.bodyAlternative
                                              .copyWith(
                                                color: AppColors.black40,
                                                fontSize: 12,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Burn badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.orange10,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '🔥 ${context.l10n.translate('burn')}',
                                        style: AppFonts.bodyAlternative
                                            .copyWith(
                                              color: AppColors.black100,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$_completedHabitsCount ${_getLocalizedHabitText(_completedHabitsCount, context)}',
                                        style: AppFonts.bodyAlternative
                                            .copyWith(
                                              color: AppColors.black60,
                                              fontSize: 11,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Line Chart
                            SizedBox(
                              height: 100,
                              child: CustomPaint(
                                size: const Size(double.infinity, 100),
                                painter: LineChartPainter(
                                  data: _selectedTabIndex == 0
                                      ? _dailyData
                                      : _selectedTabIndex == 1
                                      ? _weeklyData
                                      : _monthlyData,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // X-axis labels
                            _buildChartLabels(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
            // Сбрасываем дату на начало текущего периода при смене таба
            final now = DateTime.now();
            if (index == 0) {
              // Daily - сегодня
              _currentWeekStart = DateTime(now.year, now.month, now.day);
            } else if (index == 1) {
              // Weekly - начало текущей недели
              _currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
            } else {
              // Monthly - первое число текущего месяца
              _currentWeekStart = DateTime(now.year, now.month, 1);
            }
            _calculateStats();
            _calculateChartData();
          });
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              label,
              style: AppFonts.bodyAlternative.copyWith(
                color: isSelected ? AppColors.blue100 : AppColors.black60,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _chartLabelStyle() {
    return AppFonts.bodyAlternative.copyWith(
      color: AppColors.black40,
      fontSize: 11,
    );
  }

  Widget _buildChartLabels() {
    List<String> labels;

    switch (_selectedTabIndex) {
      case 0: // Daily - 24 часа выбранного дня (6 точек по 4 часа)
        labels = ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00'];
        break;
      case 1: // Weekly - 7 дней выбранной недели
        labels = List.generate(7, (i) {
          final date = _currentWeekStart.add(Duration(days: i));
          return '${date.day}';
        });
        break;
      case 2: // Monthly - недели выбранного месяца (7 периодов)
        final lastDayOfMonth = DateTime(
          _currentWeekStart.month == 12
              ? _currentWeekStart.year + 1
              : _currentWeekStart.year,
          _currentWeekStart.month == 12 ? 1 : _currentWeekStart.month + 1,
          0,
        ).day;
        final daysPerSlot = (lastDayOfMonth / 7).ceil().clamp(1, 31);
        labels = List.generate(7, (i) {
          final startDay = 1 + i * daysPerSlot;
          if (startDay <= lastDayOfMonth) {
            return '$startDay';
          } else {
            return '';
          }
        });
        break;
      default:
        labels = ['1', '2', '3', '4', '5', '6', '7'];
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels
          .map((label) => Text(label, style: _chartLabelStyle()))
          .toList(),
    );
  }

  void _showHabitFilterDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.black20,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.translate('selectHabit'),
                  style: AppFonts.bodyTitleMedium.copyWith(
                    color: AppColors.black100,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _habitFilterOptions.length,
                    itemBuilder: (context, index) {
                      final option = _habitFilterOptions[index];
                      final isSelected = _selectedHabitFilter == option;
                      return ListTile(
                        leading: isSelected
                            ? const Icon(Icons.check, color: AppColors.blue100)
                            : const SizedBox(width: 24),
                        title: Text(
                          _getLocalizedFilter(option, context),
                          style: AppFonts.bodyAlternative.copyWith(
                            color: isSelected
                                ? AppColors.blue100
                                : AppColors.black100,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedHabitFilter = option;
                            _calculateStats();
                            _calculateChartData();
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoodEmoji(String emoji, bool isActive) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isActive ? AppColors.orange10 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
    );
  }
}

// Simple Line Chart Painter
class LineChartPainter extends CustomPainter {
  final List<int> data;

  LineChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.blue100
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = AppColors.blue.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    // Generate points from data
    final maxValue = data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue > 0 ? maxValue : 1;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1);
      final y = 1.0 - (data[i] / safeMax); // Invert Y (top is 0)
      points.add(Offset(x.toDouble(), y.clamp(0.0, 1.0)));
    }

    // Scale points to canvas size
    final scaledPoints = points.map((p) {
      return Offset(p.dx * size.width, p.dy * size.height);
    }).toList();

    if (scaledPoints.isEmpty) return;

    // Draw curve
    path.moveTo(scaledPoints[0].dx, scaledPoints[0].dy);
    fillPath.moveTo(scaledPoints[0].dx, size.height);
    fillPath.lineTo(scaledPoints[0].dx, scaledPoints[0].dy);

    for (int i = 1; i < scaledPoints.length; i++) {
      final prev = scaledPoints[i - 1];
      final curr = scaledPoints[i];
      final cp1 = Offset(prev.dx + (curr.dx - prev.dx) / 2, prev.dy);
      final cp2 = Offset(prev.dx + (curr.dx - prev.dx) / 2, curr.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, curr.dx, curr.dy);
      fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, curr.dx, curr.dy);
    }

    fillPath.lineTo(scaledPoints.last.dx, size.height);
    fillPath.close();

    // Draw fill
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    canvas.drawPath(path, paint);

    // Draw last point highlight if data exists
    if (scaledPoints.isNotEmpty) {
      final lastPoint = scaledPoints.last;
      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final dotBorderPaint = Paint()
        ..color = AppColors.blue100
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(lastPoint, 6, dotPaint);
      canvas.drawCircle(lastPoint, 6, dotBorderPaint);
    }

    // Draw gradient fill
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.blue100.withOpacity(0.3),
          AppColors.blue100.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, gradientPaint);

    // Draw last point highlight
    final lastPoint = scaledPoints.last;
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = AppColors.blue100
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(lastPoint, 6, dotPaint);
    canvas.drawCircle(lastPoint, 6, dotBorderPaint);
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
