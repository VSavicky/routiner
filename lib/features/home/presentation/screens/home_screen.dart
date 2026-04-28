import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/core/widgets/header.dart';
import 'package:routiner/core/widgets/week_days_list.dart';
import 'package:routiner/core/widgets/joined_challenges_widget.dart';
import 'package:routiner/core/widgets/habits_widget.dart';
import 'package:routiner/core/widgets/goals_progress_widget.dart';
import 'package:routiner/core/widgets/month_calendar_widget.dart';
import 'package:routiner/features/auth/domain/entities/user_entity.dart';
import 'package:routiner/features/habits/data/models/habit_model.dart';
import 'package:routiner/features/habits/data/models/habit_log_model.dart';
import 'package:routiner/features/habits/data/repositories/habit_repository.dart';
import 'package:routiner/features/create_habit/presentation/screens/custom_habit_screen.dart';
import 'package:routiner/features/challenges/presentation/screens/challenges_list_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HabitRepository _habitRepository = HabitRepository();
  final ScrollController _scrollController = ScrollController();
  
  UserEntity? _user;
  bool _isLoading = true;
  int _selectedToggleIndex = 0;
  DateTime? _selectedDate;
  
  // Привычки пользователя
  List<HabitModel> _habits = [];
  Map<String, HabitLogModel?> _todayLogs = {}; // habitId -> log for selected date
  bool _isLoadingHabits = true;
  StreamSubscription<List<HabitModel>>? _habitsSubscription; // Подписка на стрим
  
  // Прогресс по дням недели для отображения в WeekDaysList (ключ: YYYY-MM-DD)
  Map<String, double> _dailyProgress = {};
  
  // Ключ для принудительного обновления JoinedChallengesWidget
  int _challengesRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _habitsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final docSnapshot = await _firestore.collection('users').doc(currentUser.uid).get();
      if (docSnapshot.exists) {
        setState(() {
          _user = UserEntity.fromMap(docSnapshot.data() as Map<String, dynamic>);
          _isLoading = false;
        });
      }
      
      // Загружаем привычки пользователя
      await _loadUserHabits();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingHabits = false;
      });
    }
  }
  
  /// Загрузка привычек пользователя из Firestore
  Future<void> _loadUserHabits() async {
    print('[HABITS] Loading user habits...');
    if (_habitRepository.currentUserId == null) {
      print('[HABITS] No user ID, skipping');
      setState(() => _isLoadingHabits = false);
      return;
    }
    
    // Отменяем старую подписку если есть
    await _habitsSubscription?.cancel();
    
    try {
      // Получаем привычки из Firestore
      print('[HABITS] Getting habits stream for user: ${_habitRepository.currentUserId}');
      final habitsStream = _habitRepository.getUserHabits(_habitRepository.currentUserId!);
      
      _habitsSubscription = habitsStream.listen((habits) async {
        print('[HABITS] Received ${habits.length} habits from stream');
        for (var habit in habits) {
          print('[HABITS]   Habit: ${habit.id} - ${habit.name}');
        }
        
        setState(() {
          _habits = habits;
          // Очищаем старые логи чтобы избежать отображения логов удаленных привычек
          _todayLogs.clear();
        });
        
        // Загружаем логи для сегодняшней даты только для существующих привычек
        await _loadTodayLogs();

        // Быстрый расчет прогресса для текущего дня (из уже загруженных логов)
        _recalculateTodayProgress();

        // Рассчитываем прогресс для остальных дней недели
        await _calculateDailyProgressForWeek();

        setState(() => _isLoadingHabits = false);
      }, onError: (e) {
        print('[HABITS ERROR] Stream error: $e');
        setState(() => _isLoadingHabits = false);
      });
    } catch (e, stackTrace) {
      print('[HABITS ERROR] $e');
      print('[HABITS ERROR] $stackTrace');
      setState(() => _isLoadingHabits = false);
    }
  }
  
  /// Публичный метод для обновления списка привычек (вызывается при возврате с других экранов)
  void refreshHabits() {
    _loadUserHabits();
  }
  
  /// Принудительное обновление с сервера (для pull-to-refresh)
  Future<void> _refreshHabits() async {
    print('[REFRESH] Starting refresh...');
    setState(() => _isLoadingHabits = true);
    try {
      // Отменяем старую подписку
      await _habitsSubscription?.cancel();
      
      // Загружаем привычки принудительно с сервера
      final user = _auth.currentUser;
      if (user != null) {
        print('[REFRESH] Loading habits from server...');
        final habits = await _habitRepository.getUserHabitsFromServer(user.uid);
        print('[REFRESH] Loaded ${habits.length} habits');
        
        // Сначала обновляем _habits
        setState(() {
          _habits = habits;
          _todayLogs.clear(); // Очищаем старые логи
        });
        print('[REFRESH] Updated _habits, now loading logs...');
        
        // Ждем завершения setState перед загрузкой логов
        await Future.delayed(Duration.zero);
        
        // Загружаем логи для сегодняшней даты принудительно с сервера
        await _loadTodayLogs(fromServer: true);
        print('[REFRESH] Loaded logs: ${_todayLogs.length} entries');

        // Быстрый расчет прогресса для текущего дня
        _recalculateTodayProgress();

        // Рассчитываем прогресс для остальных дней недели
        await _calculateDailyProgressForWeek();

        for (var entry in _todayLogs.entries) {
          final log = entry.value;
          if (log != null) {
            print('[REFRESH]   habitId: ${entry.key}, progress: ${log.currentProgress}/${log.targetProgress}, status: ${log.status}');
          }
        }
      }
    } catch (e, stackTrace) {
      print('[REFRESH ERROR] $e');
      print('[REFRESH ERROR] $stackTrace');
      // В случае ошибки пробуем обычную загрузку
      _loadUserHabits();
    } finally {
      setState(() => _isLoadingHabits = false);
      print('[REFRESH] Finished refresh');
    }
  }
  
  /// Загрузка логов выполнения за выбранную дату
  Future<void> _loadLogsForDate(DateTime date, {bool fromServer = false}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    print('[LOGS] Loading logs for date: $date, habits count=${_habits.length}');
    
    try {
      // Загружаем логи за выбранную дату
      final logs = fromServer 
          ? await _habitRepository.getHabitLogsForDateFromServer(user.uid, date)
          : await _habitRepository.getHabitLogsForDate(user.uid, date);
      
      print('[LOGS] Loaded ${logs.length} logs from Firestore for $date');
      
      setState(() {
        // Очищаем только логи для привычек которые существуют
        _todayLogs.clear();
        for (var log in logs) {
          // Проверяем что привычка существует в списке
          final habitExists = _habits.any((h) => h.id == log.habitId);
          if (habitExists) {
            _todayLogs[log.habitId] = log;
          }
        }
      });
    } catch (e) {
      print('[LOGS ERROR] $e');
    }
  }
  
  /// Загрузка логов выполнения за сегодня (с сервера без кэша)
  Future<void> _loadTodayLogs({bool fromServer = true}) async {
    final today = DateTime.now();
    await _loadLogsForDate(today, fromServer: fromServer);
  }
  
  /// Расчет прогресса для текущей недели
  Future<void> _calculateDailyProgressForWeek() async {
    final user = _auth.currentUser;
    if (user == null || _habits.isEmpty) return;

    // Генерируем дни текущей недели
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    // Загружаем параллельно для скорости
    final futures = weekDays.map((date) async {
      final dateKey = _dateKey(date);
      final logs = await _habitRepository.getHabitLogsForDate(user.uid, date);

      final completedCount = logs.where((log) =>
        log.status == HabitStatus.completed &&
        _habits.any((h) => h.id == log.habitId)
      ).length;

      return MapEntry(dateKey, _habits.isEmpty ? 0.0 : completedCount / _habits.length);
    }).toList();

    final results = await Future.wait(futures);
    final progress = Map<String, double>.fromEntries(results);

    if (mounted) {
      setState(() {
        // Добавляем к существующему, не перезаписываем
        _dailyProgress.addAll(progress);
      });
    }
  }
  
  /// Быстрый пересчет прогресса для выбранной даты (без запроса к БД)
  void _recalculateTodayProgress() {
    // Используем выбранную дату, а не всегда сегодня
    final effectiveDate = _selectedDate ?? DateTime.now();
    final dateKey = _dateKey(effectiveDate);
    
    // Считаем выполненные привычки из текущих логов
    final completedCount = _todayLogs.values.where((log) => 
      log?.status == HabitStatus.completed
    ).length;
    
    final progress = _habits.isEmpty ? 0.0 : completedCount / _habits.length;
    
    setState(() {
      _dailyProgress[dateKey] = progress;
    });
  }

  /// Форматирование даты в ключ YYYY-MM-DD для Map (нормализованная дата)
  String _dateKey(DateTime date) {
    // Нормализуем дату - убираем время, оставляем только дату
    final normalized = DateTime(date.year, date.month, date.day);
    return '${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';
  }

  /// Загрузка прогресса для списка дат (ленивая загрузка при скролле)
  Future<void> _loadProgressForDates(List<DateTime> dates) async {
    final user = _auth.currentUser;
    if (user == null || _habits.isEmpty || dates.isEmpty) return;

    // Фильтруем только даты без прогресса
    final datesToLoad = dates.where((date) {
      final dateKey = _dateKey(date);
      return !_dailyProgress.containsKey(dateKey);
    }).toList();

    if (datesToLoad.isEmpty) return;

    // Загружаем параллельно
    final futures = datesToLoad.map((date) async {
      final dateKey = _dateKey(date);
      final logs = await _habitRepository.getHabitLogsForDate(user.uid, date);
      final completedCount = logs.where((log) =>
        log.status == HabitStatus.completed &&
        _habits.any((h) => h.id == log.habitId)
      ).length;
      final progress = _habits.isEmpty ? 0.0 : completedCount / _habits.length;
      return MapEntry(dateKey, progress);
    }).toList();

    final results = await Future.wait(futures);
    final newProgress = Map<String, double>.fromEntries(results);

    if (mounted && newProgress.isNotEmpty) {
      setState(() {
        _dailyProgress.addAll(newProgress);
      });
    }
  }

  /// Обновить статус привычки (completed, skipped, failed)
  Future<void> _updateHabitStatus(String habitId, HabitStatus status) async {
    print('[STATUS] Updating habit $habitId to status: $status');
    try {
      // Используем выбранную дату, а не всегда сегодня
      final effectiveDate = _selectedDate ?? DateTime.now();
      final log = await _habitRepository.updateHabitStatus(habitId, effectiveDate, status);
      print('[STATUS] Updated: progress=${log.currentProgress}/${log.targetProgress}, status=${log.status}');
      
      setState(() {
        _todayLogs[habitId] = log;
        // Мгновенно обновляем прогресс для выбранной даты
        _recalculateTodayProgress();
        // Обновляем челленджи если привычка из челленджа
        _challengesRefreshKey++;
      });
    } catch (e, stackTrace) {
      print('[STATUS ERROR] $e');
      print('[STATUS ERROR] $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update habit: $e')),
      );
    }
  }
  
  /// Добавить шаг выполнения привычки
  Future<void> _incrementHabitProgress(String habitId, int increment) async {
    print('[INCREMENT] Adding $increment to habit $habitId');
    try {
      // Используем выбранную дату, а не всегда сегодня
      final effectiveDate = _selectedDate ?? DateTime.now();
      final log = await _habitRepository.incrementHabitProgress(habitId, effectiveDate, increment);
      print('[INCREMENT] Result: progress=${log.currentProgress}/${log.targetProgress}');
      setState(() {
        _todayLogs[habitId] = log;
        // Мгновенно обновляем прогресс для выбранной даты
        _recalculateTodayProgress();
        // Обновляем челленджи если привычка из челленджа
        _challengesRefreshKey++;
      });
    } catch (e, stackTrace) {
      print('[INCREMENT ERROR] $e');
      print('[INCREMENT ERROR] $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add progress: $e')),
      );
    }
  }

  /// Открыть диалог с месячным календарем
  void _showCalendarDialog() {
    // Загружаем прогресс для текущего месяца перед открытием
    final now = _selectedDate ?? DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final currentMonthDates = List.generate(
      daysInMonth,
      (index) => DateTime(now.year, now.month, index + 1),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Загружаем прогресс один раз при первой сборке
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadProgressForDates(currentMonthDates).then((_) {
              if (mounted) {
                setDialogState(() {}); // Перестраиваем диалог с новыми данными
              }
            });
          });

          return MonthCalendarDialog(
            selectedDate: _selectedDate,
            initialMonth: _selectedDate,
            dailyProgress: _dailyProgress,
            onDateSelected: (date) async {
              // Закрываем диалог сразу, до асинхронных операций
              Navigator.of(dialogContext).pop();

              setState(() {
                _selectedDate = date;
              });
              // Загружаем логи за выбранную дату
              await _loadLogsForDate(date);
              // Пересчитываем прогресс для выбранной даты
              _recalculateTodayProgress();
            },
            onMonthChanged: (month) {
              // Загружаем прогресс для всех дней выбранного месяца
              final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
              final dates = List.generate(
                daysInMonth,
                (index) => DateTime(month.year, month.month, index + 1),
              );
              _loadProgressForDates(dates).then((_) {
                if (mounted) {
                  setDialogState(() {}); // Обновляем диалог после загрузки
                }
              });
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Header(
            toggleOptions: ['Today', 'Clubs'],
            selectedToggleIndex: _selectedToggleIndex,
            notificationCount: 5, // TODO: Получать из базы данных
            userName: _user?.firstName,
            greeting: _user != null 
                ? 'Hi, ${_user!.firstName}👋' 
                : 'Hi!',
            subtitle: 'Let\'s make habbits toghether!',
            onToggleChanged: (index) {
              setState(() {
                if (index == 0 && _selectedToggleIndex == 0) {
                  // Повторное нажатие на Today - скролл наверх
                  _scrollController.animateTo(
                    0,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
                _selectedToggleIndex = index;
              });
              // TODO: Implement period change logic
            },
            onCalendarTap: _showCalendarDialog,
          ),
          // Список дней недели или страница Clubs
          Expanded(
            child: _selectedToggleIndex == 0 
                ? RefreshIndicator(
                    onRefresh: () async {
                      // Обновляем привычки при pull-to-refresh с сервера
                      await _refreshHabits();
                    },
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(), // Важно для работы RefreshIndicator
                      child: Column(
                        children: [
                          WeekDaysList(
                            selectedDate: _selectedDate,
                            dailyProgress: _dailyProgress,
                            onDateSelected: (date) async {
                              setState(() {
                                _selectedDate = date;
                              });
                              // Загружаем логи за выбранную дату
                              await _loadLogsForDate(date);
                              // Пересчитываем прогресс для обновления виджета целей
                              setState(() {});
                            },
                            onLoadProgressForDates: (dates) async {
                              // Ленивая загрузка прогресса для видимых дат
                              await _loadProgressForDates(dates);
                            },
                          ),
                        // Колонка с целями
                        Padding(
                          padding: const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Виджет выполнения целей
                              GoalsProgressWidget(
                                totalGoals: _habits.length,
                                completedGoals: _todayLogs.values.where((log) => log?.status == HabitStatus.completed).length,
                              ),
                              SizedBox(height: 16),
                              // Виджет челенджей - показывает присоединённые челленджи
                              // Key включает refreshKey и selectedDate для пересоздания при изменениях
                              // selectedDate - показывает прогресс для выбранной даты
                              JoinedChallengesWidget(
                                key: ValueKey('challenges_${_challengesRefreshKey}_${_selectedDate?.toIso8601String()}'),
                                selectedDate: _selectedDate,
                                onViewAllPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const ChallengesListScreen(),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 16),
                              // Виджет привычек - реальные данные из Firestore
                              _isLoadingHabits
                                  ? Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.blue100,
                                      ),
                                    )
                                  : _habits.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(height: 40),
                                              Text(
                                                'No habits yet',
                                                style: AppFonts.bodyTitleMedium.copyWith(
                                                  color: AppColors.black100,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Create your first habit!',
                                                style: AppFonts.bodyAlternative.copyWith(
                                                  color: AppColors.black60,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(height: 40),
                                            ],
                                          ),
                                        )
                                      : HabitsWidget(
                                          habits: _habits
                                            // Фильтруем привычки: показываем только если дата создания <= выбранная дата
                                            .where((habitModel) {
                                              final habitCreatedDate = DateTime(
                                                habitModel.createdAt.year,
                                                habitModel.createdAt.month,
                                                habitModel.createdAt.day,
                                              );
                                              final effectiveSelectedDate = _selectedDate ?? DateTime.now();
                                              final selectedDate = DateTime(
                                                effectiveSelectedDate.year,
                                                effectiveSelectedDate.month,
                                                effectiveSelectedDate.day,
                                              );
                                              return habitCreatedDate.isAtSameMomentAs(selectedDate) || 
                                                     habitCreatedDate.isBefore(selectedDate);
                                            })
                                            .map((habitModel) {
                                            // Получаем лог для выбранной даты (исторический прогресс)
                                            final dayLog = habitModel.id != null 
                                                ? _todayLogs[habitModel.id] 
                                                : null;
                                            final isCompleted = dayLog?.isCompleted ?? false;
                                            
                                            // Показываем исторический прогресс за выбранный день
                                            int currentProgress = 0;
                                            if (isCompleted) {
                                              currentProgress = habitModel.targetValue;
                                            } else if (dayLog?.value != null) {
                                              currentProgress = dayLog!.value!;
                                            }
                                            
                                            // Проверяем, является ли привычка из челленджа
                                            final isChallengeHabit = habitModel.challengeId != null && habitModel.challengeId!.isNotEmpty;
                                            
                                            return Habit(
                                              id: habitModel.id ?? '',
                                              title: habitModel.name,
                                              subtitle: '$currentProgress/${habitModel.targetValue} ${habitModel.targetUnit}',
                                              isChallenge: isChallengeHabit,
                                              friendsCount: 0, // TODO: добавить друзей
                                              currentProgress: currentProgress,
                                              targetProgress: habitModel.targetValue,
                                              emoji: habitModel.emoji,
                                              color: habitModel.colorValue,
                                              streak: 0, // TODO: вычислять streak
                                              habitType: habitModel.habitType,
                                              status: dayLog?.status ?? HabitStatus.pending,
                                              incrementStep: habitModel.incrementStep,
                                              onViewPressed: () {
                                                print('View ${habitModel.name}');
                                              },
                                              onDonePressed: () async {
                                                if (habitModel.id != null) {
                                                  await _updateHabitStatus(habitModel.id!, HabitStatus.completed);
                                                }
                                              },
                                              onAddPressed: (int step) async {
                                                if (habitModel.id != null) {
                                                  await _incrementHabitProgress(habitModel.id!, step);
                                                }
                                              },
                                              onFallPressed: () async {
                                                if (habitModel.id != null) {
                                                  await _updateHabitStatus(habitModel.id!, HabitStatus.failed);
                                                }
                                              },
                                              onSkipPressed: () async {
                                                if (habitModel.id != null) {
                                                  await _updateHabitStatus(habitModel.id!, HabitStatus.skipped);
                                                }
                                              },
                                              onEditPressed: () async {
                                                // Открываем экран редактирования с передачей данных привычки
                                                final isBadHabit = habitModel.habitType == 'quit';
                                                await Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) => CustomHabitScreen(
                                                      isBadHabit: isBadHabit,
                                                      moodEmoji: habitModel.emoji ?? '😊',
                                                      moodLabel: 'Neutral',
                                                      selectedHabitEmoji: habitModel.emoji,
                                                      onHabitCreated: () {
                                                        // Обновляем главный экран после сохранения
                                                        _refreshHabits();
                                                      },
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          }).toList(),
                                          onViewAllPressed: () {
                                            print('VIEW ALL habits pressed');
                                          },
                                        ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                : _buildClubsPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildClubsPage() {
    return Center(
      child: Text(
        'Clubs',
        style: AppFonts.headlineH5.copyWith(
          color: AppColors.black100,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
