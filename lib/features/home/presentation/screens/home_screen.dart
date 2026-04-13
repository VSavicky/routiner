import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/core/widgets/header.dart';
import 'package:routiner/core/widgets/week_days_list.dart';
import 'package:routiner/core/widgets/challenges_widget.dart';
import 'package:routiner/core/widgets/habits_widget.dart';
import 'package:routiner/core/widgets/goals_progress_widget.dart';
import 'package:routiner/features/auth/domain/entities/user_entity.dart';
import 'package:routiner/features/habits/data/models/habit_model.dart';
import 'package:routiner/features/habits/data/models/habit_log_model.dart';
import 'package:routiner/features/habits/data/repositories/habit_repository.dart';
import 'package:routiner/features/create_habit/presentation/screens/custom_habit_screen.dart';

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
  Map<String, HabitLogModel?> _todayLogs = {}; // habitId -> log
  bool _isLoadingHabits = true;
  StreamSubscription<List<HabitModel>>? _habitsSubscription; // Подписка на стрим

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
  
  /// Загрузка логов выполнения за сегодня (с сервера без кэша)
  Future<void> _loadTodayLogs({bool fromServer = true}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    print('[LOGS] Loading logs fromServer=$fromServer, habits count=${_habits.length}');
    
    try {
      final today = DateTime.now();
      // Загружаем логи с сервера чтобы избежать проблемы с кэшем
      final logs = fromServer 
          ? await _habitRepository.getHabitLogsForDateFromServer(user.uid, today)
          : await _habitRepository.getHabitLogsForDate(user.uid, today);
      
      print('[LOGS] Loaded ${logs.length} logs from Firestore');
      for (var log in logs) {
        print('[LOGS]   Firestore log: habitId=${log.habitId}, progress=${log.currentProgress}/${log.targetProgress}, status=${log.status}');
      }
      
      setState(() {
        // Очищаем только логи для привычек которые существуют
        _todayLogs.clear();
        for (var log in logs) {
          // Проверяем что привычка существует в списке
          final habitExists = _habits.any((h) => h.id == log.habitId);
          print('[LOGS] Checking habitId=${log.habitId}, exists=$habitExists');
          if (habitExists) {
            _todayLogs[log.habitId] = log;
            print('[LOGS]   Added to _todayLogs: ${log.habitId}');
          } else {
            print('[LOGS]   Skipped (habit not in list): ${log.habitId}');
          }
        }
        print('[LOGS] Final _todayLogs count: ${_todayLogs.length}');
      });
    } catch (e, stackTrace) {
      print('[LOGS ERROR] $e');
      print('[LOGS ERROR] $stackTrace');
    }
  }
  
  /// Обновить статус привычки (completed, skipped, failed)
  Future<void> _updateHabitStatus(String habitId, HabitStatus status) async {
    print('[STATUS] Updating habit $habitId to status: $status');
    try {
      final log = await _habitRepository.updateHabitStatus(habitId, DateTime.now(), status);
      print('[STATUS] Updated: progress=${log.currentProgress}/${log.targetProgress}, status=${log.status}');
      setState(() {
        _todayLogs[habitId] = log;
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
      // Добавляем шаг в зависимости от типа привычки
      // Например: +1 раз, +100 шагов, +200ml, +15 минут и т.д.
      final log = await _habitRepository.incrementHabitProgress(habitId, DateTime.now(), increment);
      print('[INCREMENT] Result: progress=${log.currentProgress}/${log.targetProgress}');
      setState(() {
        _todayLogs[habitId] = log;
      });
    } catch (e, stackTrace) {
      print('[INCREMENT ERROR] $e');
      print('[INCREMENT ERROR] $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add progress: $e')),
      );
    }
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
                            onDateSelected: (date) {
                              setState(() {
                                _selectedDate = date;
                              });
                              // TODO: Implement date selection logic
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
                                totalGoals: 4,
                                completedGoals: 1,
                              ),
                              SizedBox(height: 16),
                              // Виджет челенджей
                              ChallengesWidget(
                                title: 'Best Runners!',
                                subtitle: '5 days 13 ours left',
                                friendsCount: 3,
                                onViewAllPressed: () {
                                  // TODO: Обработать нажатие на VIEW ALL
                                  print('VIEW ALL pressed');
                                },
                                onContainerPressed: () {
                                  // TODO: Обработать нажатие на контейнер
                                  print('Container pressed');
                                },
                                onFriendsPressed: () {
                                  // TODO: Обработать нажатие на друзей
                                  print('Friends pressed');
                                },
                                onAddFriendPressed: () {
                                  // TODO: Обработать нажатие на добавление друга
                                  print('Add friend pressed');
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
                                      ? Container(
                                          padding: EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.calendar_today_outlined,
                                                size: 48,
                                                color: AppColors.black40,
                                              ),
                                              SizedBox(height: 12),
                                              Text(
                                                'No habits yet',
                                                style: AppFonts.bodyTitleMedium.copyWith(
                                                  color: AppColors.black100,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Create your first habit!',
                                                style: AppFonts.bodyAlternative.copyWith(
                                                  color: AppColors.black60,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : HabitsWidget(
                                          habits: _habits.map((habitModel) {
                                            // Получаем лог для сегодня
                                            final todayLog = habitModel.id != null 
                                                ? _todayLogs[habitModel.id] 
                                                : null;
                                            final isCompleted = todayLog?.isCompleted ?? false;
                                            
                                            // Рассчитываем прогресс
                                            int currentProgress = 0;
                                            if (isCompleted) {
                                              currentProgress = habitModel.targetValue;
                                            } else if (todayLog?.value != null) {
                                              currentProgress = todayLog!.value!;
                                            }
                                            
                                            return Habit(
                                              id: habitModel.id ?? '',
                                              title: habitModel.name,
                                              subtitle: '$currentProgress/${habitModel.targetValue} ${habitModel.targetUnit}',
                                              friendsCount: 0, // TODO: добавить друзей
                                              currentProgress: currentProgress,
                                              targetProgress: habitModel.targetValue,
                                              emoji: habitModel.emoji,
                                              color: habitModel.colorValue,
                                              streak: 0, // TODO: вычислять streak
                                              habitType: habitModel.habitType,
                                              status: todayLog?.status ?? HabitStatus.pending,
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
