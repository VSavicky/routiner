import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/core/widgets/header.dart';
import 'package:routiner/l10n/app_localizations.dart';
import 'package:routiner/core/widgets/week_days_list.dart';
import 'package:routiner/core/widgets/joined_challenges_widget.dart';
import 'package:routiner/core/widgets/habits_widget.dart';
import 'package:routiner/core/widgets/goals_progress_widget.dart';
import 'package:routiner/core/widgets/month_calendar_widget.dart';
import 'package:routiner/features/auth/domain/entities/user_entity.dart';
import 'package:routiner/features/habits/data/models/habit_model.dart';
import 'package:routiner/features/habits/data/models/habit_log_model.dart';
import 'package:routiner/features/habits/data/repositories/habit_repository.dart';
import 'package:routiner/features/challenges/presentation/screens/challenges_list_screen.dart';
import 'package:routiner/features/challenges/presentation/screens/challenge_detail_screen.dart';
import 'package:routiner/features/habits/presentation/screens/habits_list_screen.dart';
import 'package:routiner/features/habits/presentation/screens/habit_detail_screen.dart';
import 'package:routiner/features/clubs/presentation/screens/club_detail_screen.dart';
import 'package:routiner/features/clubs/presentation/screens/clubs_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:routiner/features/achievements/data/services/achievement_service.dart';

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
  
  // Присоединенные клубы
  List<Map<String, dynamic>> _joinedClubs = [];
  bool _isLoadingClubs = true;

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
      
      // Загружаем присоединенные клубы
      await _loadJoinedClubs();
    } catch (e) {
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('permission-denied') || errorMsg.contains('permission denied')) {
        print('[HOME ERROR] Permission denied, user likely signed out');
        if (mounted) {
          await FirebaseAuth.instance.signOut();
          if (mounted) context.go('/auth');
        }
        return;
      }
      setState(() {
        _isLoading = false;
        _isLoadingHabits = false;
        _isLoadingClubs = false;
      });
    }
  }
  
  String _getLocalizedHabitName(String habitName) {
    switch (habitName) {
      case 'Drink water':
        return context.l10n.translate('drinkWater');
      case 'Daily workout':
        return context.l10n.translate('dailyWorkout');
      case 'Take 8K steps':
        return context.l10n.translate('take8KSteps');
      case 'Meditate':
        return context.l10n.translate('meditate');
      case 'Morning stretch':
        return context.l10n.translate('morningStretch');
      case 'Read book':
        return context.l10n.translate('readBook');
      case 'Eat vegetables':
        return context.l10n.translate('eatVegetables');
      case 'Cook at home':
        return context.l10n.translate('cookAtHome');
      case 'No phone 1h before bed':
        return context.l10n.translate('noPhone1hBeforeBed');
      case 'Read instead':
        return context.l10n.translate('readInstead');
      case 'No sugar':
        return context.l10n.translate('noSugar');
      case 'Max 1 coffee':
        return context.l10n.translate('max1Coffee');
      case 'Drink herbal tea':
        return context.l10n.translate('drinkHerbalTea');
      case 'Complete 3 priorities':
        return context.l10n.translate('complete3Priorities');
      case 'No social media at work':
        return context.l10n.translate('noSocialMediaAtWork');
      case 'Max 1h TV/Netflix':
        return context.l10n.translate('max1hTvNetflix');
      case 'Go for a walk':
        return context.l10n.translate('goForAWalk');
      case 'cycling':
      case 'Cycling':
        return context.l10n.translate('cycling');
      case 'running':
        return context.l10n.translate('running');
      case 'meditation':
        return context.l10n.translate('meditation');
      case 'reading':
        return context.l10n.translate('reading');
      case 'fitness':
        return context.l10n.translate('fitness');
      case 'healthyEating':
        return context.l10n.translate('healthyEating');
      case 'drinkingWater':
        return context.l10n.translate('drinkingWater');
      case 'sleepSchedule':
        return context.l10n.translate('sleepSchedule');
      case 'journaling':
        return context.l10n.translate('journaling');
      case 'creativeWork':
        return context.l10n.translate('creativeWork');
      default:
        return habitName;
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
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('permission-denied') || errorMsg.contains('permission denied')) {
          print('[HABITS ERROR] Permission denied, user likely signed out');
          if (mounted) {
            FirebaseAuth.instance.signOut().then((_) {
              if (mounted) context.go('/auth');
            });
          }
        }
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
  
  /// Загрузка присоединенных клубов из SharedPreferences
  Future<void> _loadJoinedClubs() async {
    print('[CLUBS] Loading joined clubs...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final joinedClubIds = prefs.getStringList('joined_clubs') ?? [];
      
      // Все доступные клубы (те же что в ClubsListScreen)
      final allClubs = [
        {
          'id': 'cat_lovers',
          'name': context.l10n.translate('catLovers'),
          'description': context.l10n.translate('catLoversDescription'),
          'emoji': '🐱',
          'members': '500+',
          'color': const Color(0xFFFF6B6B),
          'habits': [
            {'title': context.l10n.translate('morningPetCare'), 'emoji': '🐾', 'targetValue': 15, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
            {'title': context.l10n.translate('catFeedingRoutine'), 'emoji': '🥫', 'targetValue': 2, 'targetUnit': 'times', 'incrementStep': 1, 'habitType': 'build'},
            {'title': context.l10n.translate('playWithCat'), 'emoji': '🎾', 'targetValue': 20, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
          ],
        },
        {
          'id': 'book_worms',
          'name': context.l10n.translate('bookWorms'),
          'description': context.l10n.translate('bookWormsDescription'),
          'emoji': '📚',
          'members': '1.2k',
          'color': const Color(0xFF4ECDC4),
          'habits': [
            {'title': context.l10n.translate('dailyReading'), 'emoji': '📖', 'targetValue': 30, 'targetUnit': 'min', 'incrementStep': 10, 'habitType': 'build'},
            {'title': context.l10n.translate('bookNotes'), 'emoji': '📝', 'targetValue': 1, 'targetUnit': 'page', 'incrementStep': 1, 'habitType': 'build'},
            {'title': context.l10n.translate('libraryVisit'), 'emoji': '🏛️', 'targetValue': 1, 'targetUnit': 'visit', 'incrementStep': 1, 'habitType': 'build'},
          ],
        },
        {
          'id': 'runners',
          'name': context.l10n.translate('runners'),
          'description': context.l10n.translate('runnersDescription'),
          'emoji': '🏃',
          'members': '800+',
          'color': const Color(0xFF95E1D3),
          'habits': [
            {'title': context.l10n.translate('morningRun'), 'emoji': '🏃', 'targetValue': 5, 'targetUnit': 'km', 'incrementStep': 1, 'habitType': 'build'},
            {'title': context.l10n.translate('stretching'), 'emoji': '🤸', 'targetValue': 10, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
            {'title': context.l10n.translate('hydration'), 'emoji': '💧', 'targetValue': 8, 'targetUnit': 'glasses', 'incrementStep': 1, 'habitType': 'build'},
          ],
        },
        {
          'id': 'yoga_life',
          'name': context.l10n.translate('yogaLife'),
          'description': context.l10n.translate('yogaLifeDescription'),
          'emoji': '🧘',
          'members': '2k',
          'color': const Color(0xFFA8E6CF),
          'habits': [
            {'title': context.l10n.translate('morningYoga'), 'emoji': '🧘', 'targetValue': 20, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
            {'title': context.l10n.translate('meditation'), 'emoji': '🧠', 'targetValue': 10, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
            {'title': context.l10n.translate('breathingExercises'), 'emoji': '🌬️', 'targetValue': 5, 'targetUnit': 'min', 'incrementStep': 1, 'habitType': 'build'},
          ],
        },
        {
          'id': 'meditation',
          'name': context.l10n.translate('meditationClub'),
          'description': context.l10n.translate('meditationClubDescription'),
          'emoji': '🧠',
          'members': '3k+',
          'color': const Color(0xFFC7CEEA),
          'habits': [
            {'title': context.l10n.translate('dailyMeditation'), 'emoji': '🧘', 'targetValue': 15, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
            {'title': context.l10n.translate('mindfulBreathing'), 'emoji': '🌬️', 'targetValue': 10, 'targetUnit': 'min', 'incrementStep': 2, 'habitType': 'build'},
            {'title': context.l10n.translate('gratitudeJournal'), 'emoji': '📔', 'targetValue': 3, 'targetUnit': 'items', 'incrementStep': 1, 'habitType': 'build'},
          ],
        },
        {
          'id': 'fitness_gurus',
          'name': context.l10n.translate('fitnessGurus'),
          'description': context.l10n.translate('fitnessGurusDescription'),
          'emoji': '💪',
          'members': '1.5k',
          'color': const Color(0xFFFFD93D),
          'habits': [
            {'title': context.l10n.translate('strengthTraining'), 'emoji': '💪', 'targetValue': 30, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
            {'title': context.l10n.translate('proteinIntake'), 'emoji': '🥗', 'targetValue': 25, 'targetUnit': 'grams', 'incrementStep': 5, 'habitType': 'build'},
            {'title': context.l10n.translate('recoveryStretching'), 'emoji': '🤸', 'targetValue': 15, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
          ],
        },
        {
          'id': 'creative_minds',
          'name': context.l10n.translate('creativeMinds'),
          'description': context.l10n.translate('creativeMindsDescription'),
          'emoji': '🎨',
          'members': '750+',
          'color': const Color(0xFFE8B4F8),
          'habits': [
            {'title': context.l10n.translate('dailySketch'), 'emoji': '✏️', 'targetValue': 30, 'targetUnit': 'min', 'incrementStep': 10, 'habitType': 'build'},
            {'title': context.l10n.translate('creativeWriting'), 'emoji': '✍️', 'targetValue': 200, 'targetUnit': 'words', 'incrementStep': 50, 'habitType': 'build'},
            {'title': context.l10n.translate('inspirationGathering'), 'emoji': '💡', 'targetValue': 15, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
          ],
        },
        {
          'id': 'eco_warriors',
          'name': context.l10n.translate('ecoWarriors'),
          'description': context.l10n.translate('ecoWarriorsDescription'),
          'emoji': '🌱',
          'members': '900+',
          'color': const Color(0xFF90EE90),
          'habits': [
            {'title': context.l10n.translate('recycling'), 'emoji': '♻️', 'targetValue': 5, 'targetUnit': 'items', 'incrementStep': 1, 'habitType': 'build'},
            {'title': context.l10n.translate('waterConservation'), 'emoji': '💧', 'targetValue': 10, 'targetUnit': 'liters', 'incrementStep': 2, 'habitType': 'build'},
            {'title': context.l10n.translate('plasticReduction'), 'emoji': '🚫', 'targetValue': 3, 'targetUnit': 'items', 'incrementStep': 1, 'habitType': 'quit'},
          ],
        },
      ];
      
      // Фильтруем только присоединенные клубы
      final clubs = allClubs.where((club) => joinedClubIds.contains(club['id'] as String)).toList();
      
      // Отладочная информация
      for (final club in clubs) {
        final habits = club['habits'] as List<dynamic>? ?? [];
        print('[CLUBS] Club: ${club['name']}, habits count: ${habits.length}');
        for (final habit in habits) {
          print('[CLUBS]   Habit: ${habit['title']}');
        }
      }
      
      setState(() {
        _joinedClubs = clubs;
        _isLoadingClubs = false;
      });
      
      print('[CLUBS] Loaded ${clubs.length} joined clubs');
    } catch (e) {
      print('[CLUBS ERROR] $e');
      setState(() {
        _isLoadingClubs = false;
      });
    }
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

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isFutureDate(DateTime date) {
    return _dateOnly(date).isAfter(_dateOnly(DateTime.now()));
  }

  void _showFutureDateActionMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.translate('cannotCompleteFutureDates')),
      ),
    );
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
      if (_isFutureDate(effectiveDate)) {
        _showFutureDateActionMessage();
        return;
      }

      final log = await _habitRepository.updateHabitStatus(habitId, effectiveDate, status);
      print('[STATUS] Updated: progress=${log.currentProgress}/${log.targetProgress}, status=${log.status}');
      
      setState(() {
        _todayLogs[habitId] = log;
        // Мгновенно обновляем прогресс для выбранной даты
        _recalculateTodayProgress();
        // Обновляем челленджи если привычка из челленджа
        _challengesRefreshKey++;
      });
      
      // Если привычка выполнена - проверяем достижения
      if (status == HabitStatus.completed) {
        // Добавляем небольшую задержку чтобы habitLog успел сохраниться в Firestore
        await Future.delayed(const Duration(milliseconds: 500));
        await _checkAchievementsAfterHabitCompletion();
      }
    } catch (e, stackTrace) {
      print('[STATUS ERROR] $e');
      print('[STATUS ERROR] $stackTrace');
      
      // Проверяем, является ли ошибка временной проблемой сети
      final errorMessage = e.toString().toLowerCase();
      final isTemporaryError = errorMessage.contains('unavailable') || 
                               errorMessage.contains('network') || 
                               errorMessage.contains('timeout');
      
      if (isTemporaryError) {
        // Для временных ошибок показываем кнопку повтора
        final snackBar = SnackBar(
          content: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.translate('temporaryErrorTryAgain'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Закрываем snackbar
                  _updateHabitStatus(habitId, status); // Пробуем снова
                },
                child: Text(
                  context.l10n.translate('retry') ?? 'Повторить',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 6),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.translate('failedToUpdateHabit')}: $e'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
    
  /// Проверить достижения после выполнения привычки
  Future<void> _checkAchievementsAfterHabitCompletion() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('[ACHIEVEMENT] Checking achievements after habit completion for user: ${user.uid}');
        
        // Импортируем AchievementService
        final achievementService = AchievementService();
        
        // Проверяем достижение за первую выполненную привычку
        await achievementService.checkAndAwardFirstHabitAchievement(user.uid);
        
        // Проверяем достижения за очки
        await achievementService.checkAndAwardPointsAchievements(user.uid);
        
        print('[ACHIEVEMENT] Achievement check completed after habit completion');
      }
    } catch (e) {
      print('[ACHIEVEMENT ERROR] Failed to check achievements after habit completion: $e');
    }
  }
  
  /// Добавить шаг выполнения привычки
  Future<void> _incrementHabitProgress(String habitId, int increment) async {
    print('[INCREMENT] Adding $increment to habit $habitId');
    try {
      // Используем выбранную дату, а не всегда сегодня
      final effectiveDate = _selectedDate ?? DateTime.now();
      if (_isFutureDate(effectiveDate)) {
        _showFutureDateActionMessage();
        return;
      }

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
      
      final errorMessage = e.toString().toLowerCase();
      final isTemporaryError = errorMessage.contains('unavailable') || 
                               errorMessage.contains('network') || 
                               errorMessage.contains('timeout');
      
      if (isTemporaryError) {
        final snackBar = SnackBar(
          content: Row(
            children: [
              Expanded(
                child: Text(context.l10n.translate('temporaryErrorTryAgain')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _incrementHabitProgress(habitId, increment);
                },
                child: Text(
                  context.l10n.translate('retry') ?? 'Повторить',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 6),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.translate('failedToAddProgress')}: $e'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
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
            l10n: context.l10n,
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
            toggleOptions: [context.l10n.translate('today'), context.l10n.translate('clubs')],
            selectedToggleIndex: _selectedToggleIndex,
            notificationCount: _joinedClubs.length,
            userName: _user?.firstName,
            greeting: _user != null 
                ? context.l10n.translate('hiWithName').replaceAll('{name}', _user!.firstName)
                : context.l10n.translate('hi'),
            subtitle: context.l10n.translate('letsMakeHabitsTogether'),
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
                            onFutureDateTapped: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.l10n.translate('cannotCompleteFutureDates')),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            onDateSelected: (date) async {
                              print('[HOME] Date selected: $date');
                              print('[HOME] Is future: ${_getIsFutureDate()}');
                              setState(() {
                                _selectedDate = date;
                              });
                              // Загружаем логи за выбранную дату
                              await _loadLogsForDate(date);
                              // Пересчитываем прогресс для обновления виджета целей
                              setState(() {});
                              print('[HOME] Selected date updated: ${_selectedDate}');
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
                                l10n: context.l10n,
                              ),
                              SizedBox(height: 16),
                              // Виджет челенджей - показывает присоединённые челленджи
                              // Key включает refreshKey и selectedDate для пересоздания при изменениях
                              // selectedDate - показывает прогресс для выбранной даты
                              JoinedChallengesWidget(
                                key: ValueKey('challenges_${_challengesRefreshKey}_${_selectedDate?.toIso8601String()}'),
                                selectedDate: _selectedDate,
                                l10n: context.l10n,
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
                                                context.l10n.translate('noHabitsYet'),
                                                style: AppFonts.bodyTitleMedium.copyWith(
                                                  color: AppColors.black100,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                context.l10n.translate('createFirstHabit'),
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
                                            // Для будущих дат показываем только pending привычки, для остальных - только pending
                                            .where((habitModel) {
                                              final dayLog = habitModel.id != null ? _todayLogs[habitModel.id] : null;
                                              final status = dayLog?.status ?? HabitStatus.pending;
                                              // Для будущих дат показываем только pending
                                              if (_getIsFutureDate()) {
                                                return status == HabitStatus.pending;
                                              }
                                              // Для текущих и прошлых дат показываем только pending (выполненные/проваленные/пропущенные сразу исчезают)
                                              return status == HabitStatus.pending;
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

                                            // Проверяем, является ли привычка из челленджа или клуба
                                            final isChallengeHabit = habitModel.challengeId != null && habitModel.challengeId!.isNotEmpty;
                                            final isClubHabit = isChallengeHabit && habitModel.challengeId!.startsWith('club_');

                                            return Habit(
                                              id: habitModel.id ?? '',
                                              title: _getLocalizedHabitName(habitModel.name),
                                              subtitle: '$currentProgress/${habitModel.targetValue} ${habitModel.targetUnit}',
                                              targetUnit: habitModel.targetUnit,
                                              isChallenge: isChallengeHabit,
                                              challengeId: habitModel.challengeId,
                                              challengeName: null, // TODO: загрузить имя челленджа
                                              isClubHabit: isClubHabit,
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
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) => HabitDetailScreen(
                                                      habit: habitModel,
                                                      challengeId: habitModel.challengeId,
                                                    ),
                                                  ),
                                                );
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
                                              onEditPressed: () {
                                                // Открываем детальный экран привычки
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) => HabitDetailScreen(
                                                      habit: habitModel,
                                                      challengeId: habitModel.challengeId,
                                                    ),
                                                  ),
                                                );
                                              },
                                              l10n: context.l10n,
                                            );
                                          }).toList(),
                                          l10n: context.l10n,
                                          isReadOnly: _getIsFutureDate(),
                                          onViewAllPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => HabitsListScreen(
                                                  selectedDate: _selectedDate,
                                                ),
                                              ),
                                            );
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

  /// Проверка: является ли выбранная дата будущей
  bool _getIsFutureDate() {
    if (_selectedDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
    return selected.isAfter(today);
  }

  Widget _buildClubsPage() {
    if (_isLoadingClubs) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_joinedClubs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.black10,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.groups,
                size: 40,
                color: AppColors.black40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.translate('noClubsYet'),
              style: AppFonts.headlineH5.copyWith(
                color: AppColors.black100,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.translate('joinClubsFromExplore'),
              style: AppFonts.bodyAlternative.copyWith(
                color: AppColors.black60,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ClubsListScreen(),
                  ),
                ).then((_) {
                  // Обновляем список клубов при возврате со списка клубов
                  _loadJoinedClubs();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue100,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                context.l10n.translate('exploreClubs'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        await _loadJoinedClubs();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                context.l10n.translate('yourClubs'),
                style: AppFonts.headlineH5.copyWith(
                  color: AppColors.black100,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Список присоединенных клубов
            ..._joinedClubs.map((club) {
              return GestureDetector(
                onTap: () {
                  print('[HOME] Tapping club: ${club['name']}');
                  print('[HOME] Club keys before navigation: ${club.keys}');
                  final habits = club['habits'] as List<dynamic>? ?? [];
                  print('[HOME] Habits count before navigation: ${habits.length}');
                  
                  // Создаем полную копию данных клуба с привычками
                  final clubWithHabits = <String, dynamic>{};
                  clubWithHabits.addAll(club);
                  
                  // Убедимся что привычки есть в копии
                  if (habits.isNotEmpty) {
                    clubWithHabits['habits'] = habits;
                    print('[HOME] Created club copy with ${habits.length} habits');
                  }
                  
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ClubDetailScreen(
                        club: clubWithHabits,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        club['color'] as Color,
                        (club['color'] as Color).withOpacity(0.8),
                      ],
                      stops: [0.0, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Иконка клуба
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              club['emoji'] as String,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Информация о клубе
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                club['name'] as String,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                club['description'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${(club['habits'] as List<dynamic>).length} ${context.l10n.translate('habits')}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    club['members'] as String,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
