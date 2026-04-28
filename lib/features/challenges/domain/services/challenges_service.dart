import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:routiner/core/constants/app_colors.dart';
import '../../../habits/data/models/habit_model.dart';
import '../../../habits/data/repositories/habit_repository.dart';
import '../../data/models/challenge_habit_model.dart';
import '../../data/repositories/challenge_habit_repository.dart';

class ChallengesService {
  static const String _joinedChallengesKey = 'joined_challenges';
  
  static final ChallengesService _instance = ChallengesService._internal();
  factory ChallengesService() => _instance;
  ChallengesService._internal();

  final ChallengeHabitRepository _challengeHabitRepository = ChallengeHabitRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  /// Получить текущего пользователя
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  /// Получить ChallengeHabitRepository
  ChallengeHabitRepository get challengeHabitRepository => _challengeHabitRepository;

  // Конвертировать челлендж в JSON-serializable формат
  Map<String, dynamic> _challengeToJson(Map<String, dynamic> challenge) {
    final Map<String, dynamic> json = {};
    
    challenge.forEach((key, value) {
      if (value is DateTime) {
        json[key] = value.toIso8601String();
      } else if (value is Color) {
        // Сохраняем цвет как строку
        if (value == AppColors.blue) {
          json[key] = 'blue';
        } else if (value == AppColors.purple) {
          json[key] = 'purple';
        } else if (value == AppColors.orange) {
          json[key] = 'orange';
        } else if (value == AppColors.green) {
          json[key] = 'green';
        } else if (value == AppColors.red) {
          json[key] = 'red';
        } else {
          json[key] = 'blue'; // Default
        }
      } else if (value is List) {
        // Рекурсивно конвертируем элементы списка
        json[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _challengeToJson(item);
          }
          return item;
        }).toList();
      } else if (value is Map<String, dynamic>) {
        json[key] = _challengeToJson(value);
      } else {
        json[key] = value;
      }
    });
    
    return json;
  }

  // Конвертировать JSON обратно в челлендж с Color
  Map<String, dynamic> _jsonToChallenge(Map<String, dynamic> json) {
    final Map<String, dynamic> challenge = {};
    
    json.forEach((key, value) {
      if (key == 'endTime' || key == 'joinedAt' || key == 'startDate' || key == 'endDate') {
        // Парсим дату
        if (value is String) {
          try {
            challenge[key] = DateTime.parse(value);
          } catch (e) {
            if (key == 'endTime' || key == 'endDate') {
              challenge[key] = DateTime.now().add(const Duration(days: 7));
            } else {
              challenge[key] = DateTime.now();
            }
          }
        } else if (value is DateTime) {
          // Уже DateTime, оставляем как есть
          challenge[key] = value;
        } else {
          challenge[key] = value;
        }
      } else if (key == 'color' && value is String) {
        // Восстанавливаем цвет
        switch (value) {
          case 'blue':
            challenge[key] = AppColors.blue;
            break;
          case 'purple':
            challenge[key] = AppColors.purple;
            break;
          case 'orange':
            challenge[key] = AppColors.orange;
            break;
          case 'green':
            challenge[key] = AppColors.green;
            break;
          case 'red':
            challenge[key] = AppColors.red;
            break;
          default:
            challenge[key] = AppColors.blue;
        }
      } else if (value is List) {
        challenge[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _jsonToChallenge(item);
          }
          return item;
        }).toList();
      } else if (value is Map<String, dynamic>) {
        challenge[key] = _jsonToChallenge(value);
      } else {
        challenge[key] = value;
      }
    });
    
    return challenge;
  }

  // Получить список присоединённых челленджей
  Future<List<Map<String, dynamic>>> getJoinedChallenges() async {
    final prefs = await _prefs;
    final String? jsonString = prefs.getString(_joinedChallengesKey);
    
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) => _jsonToChallenge(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // Получить челленджи, активные на указанную дату
  // Если date = null, возвращает активные на сегодня челленджи
  Future<List<Map<String, dynamic>>> getJoinedChallengesForDate(DateTime? date) async {
    final allChallenges = await getJoinedChallenges();
    final targetDate = date ?? DateTime.now();
    
    // Начало и конец целевого дня
    final targetDayStart = DateTime(targetDate.year, targetDate.month, targetDate.day);
    
    return allChallenges.where((challenge) {
      // startDate может быть String или DateTime
      final startDateRaw = challenge['startDate'];
      final endDateRaw = challenge['endDate'];
      final joinedAtRaw = challenge['joinedAt'];
      final endTimeRaw = challenge['endTime'];
      
      // Хелпер для получения DateTime из String или DateTime
      DateTime? parseDate(dynamic value) {
        if (value is String) {
          return DateTime.tryParse(value);
        } else if (value is DateTime) {
          return value;
        }
        return null;
      }
      
      // Если есть фиксированные даты, используем их
      DateTime? startDate;
      DateTime? endDate;
      
      startDate = parseDate(startDateRaw);
      if (startDate == null) {
        // Для старых челленджей используем joinedAt как startDate
        startDate = parseDate(joinedAtRaw);
      }
      
      endDate = parseDate(endDateRaw);
      if (endDate == null) {
        // Для старых челленджей используем endTime
        endDate = parseDate(endTimeRaw);
      }
      
      // Если нет дат, показываем всегда (обратная совместимость)
      if (startDate == null && endDate == null) {
        return true;
      }
      
      // Показываем челлендж только если targetDate между startDate и endDate
      // Или targetDate совпадает с одной из этих дат
      final effectiveStart = startDate ?? DateTime(2000);
      final effectiveEnd = endDate ?? DateTime(2100);
      
      // Начало и конец дня челленджа
      final challengeStartDay = DateTime(effectiveStart.year, effectiveStart.month, effectiveStart.day);
      final challengeEndDay = DateTime(effectiveEnd.year, effectiveEnd.month, effectiveEnd.day);
      
      // Челлендж активен если targetDayStart между challengeStartDay и challengeEndDay (включительно)
      return !targetDayStart.isBefore(challengeStartDay) && !targetDayStart.isAfter(challengeEndDay);
    }).toList();
  }

  // Присоединиться к челленджу
  Future<void> joinChallenge(Map<String, dynamic> challenge) async {
    final prefs = await _prefs;
    final joinedChallenges = await getJoinedChallenges();
    
    // Проверяем, не присоединён ли уже
    final String challengeId = challenge['id'] as String? ?? challenge['title'] as String;
    final bool alreadyJoined = joinedChallenges.any((c) => 
      (c['id'] as String? ?? c['title']) == challengeId
    );
    
    if (!alreadyJoined) {
      // Конвертируем новый челлендж в JSON-формат
      final jsonChallenge = _challengeToJson({...challenge});
      
      // Вычисляем фиксированные даты начала и окончания
      final now = DateTime.now();
      final originalEndTime = challenge['endTime'] as DateTime?;
      final duration = originalEndTime?.difference(now) ?? const Duration(days: 7);
      
      // Добавляем метку времени присоединения и фиксированные даты
      final challengeWithDates = {
        ...jsonChallenge,
        'joinedAt': now.toIso8601String(),
        'startDate': now.toIso8601String(), // Фиксированная дата начала
        'endDate': now.add(duration).toIso8601String(), // Фиксированная дата окончания
        'id': challengeId,
      };
      
      joinedChallenges.add(challengeWithDates);
      
      // Конвертируем ВСЕ челленджи в JSON перед сохранением
      final jsonList = joinedChallenges.map((c) => _challengeToJson(c)).toList();
      final String jsonString = jsonEncode(jsonList);
      await prefs.setString(_joinedChallengesKey, jsonString);
      
      // Создаём привычки челленджа в Firestore
      final userId = currentUserId;
      if (userId != null) {
        await _createChallengeHabits(userId, challengeId, challenge);
      }
    }
  }

  // Покинуть челлендж
  Future<void> leaveChallenge(String challengeId) async {
    final prefs = await _prefs;
    final joinedChallenges = await getJoinedChallenges();
    
    joinedChallenges.removeWhere((c) => 
      (c['id'] as String? ?? c['title']) == challengeId
    );
    
    // Конвертируем все челленджи обратно в JSON-формат
    final jsonList = joinedChallenges.map((c) => _challengeToJson(c)).toList();
    final String jsonString = jsonEncode(jsonList);
    await prefs.setString(_joinedChallengesKey, jsonString);
    
    // Удаляем привычки челленджа из Firestore
    final userId = currentUserId;
    if (userId != null) {
      await _deleteChallengeHabits(userId, challengeId);
    }
  }

  // Проверить, присоединён ли пользователь к челленджу
  Future<bool> isJoined(String challengeId) async {
    final joinedChallenges = await getJoinedChallenges();
    return joinedChallenges.any((c) => 
      (c['id'] as String? ?? c['title']) == challengeId
    );
  }

  // Очистить все челленджи (для тестирования)
  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.remove(_joinedChallengesKey);
  }

  // ==================== CHALLENGE HABITS ====================

  /// Получить привычки челленджа
  Stream<List<ChallengeHabitModel>> getChallengeHabits(String userId, String challengeId) {
    return _challengeHabitRepository.getUserChallengeHabits(userId, challengeId);
  }

  /// Получить привычки челленджа (Future)
  Future<List<ChallengeHabitModel>> getChallengeHabitsFuture(String userId, String challengeId) async {
    return _challengeHabitRepository.getUserChallengeHabitsFuture(userId, challengeId);
  }

  /// Получить статистику челленджа (Future)
  Future<Map<String, dynamic>> getChallengeStats(String userId, String challengeId) async {
    return _challengeHabitRepository.getChallengeStats(userId, challengeId);
  }

  /// Получить статистику челленджа в реальном времени (Stream)
  /// date - дата для которой показывать прогресс (null = сегодня)
  Stream<Map<String, dynamic>> getChallengeStatsStream(
    String userId,
    String challengeId, {
    DateTime? date,
  }) {
    return _challengeHabitRepository.getChallengeStatsStream(userId, challengeId, date: date);
  }

  /// Отметить день челленджа как завершенный
  Future<void> markChallengeDayCompleted(String userId, String challengeId, DateTime date) async {
    return _challengeHabitRepository.markChallengeDayCompleted(userId, challengeId, date);
  }

  /// Получить прогресс челленджа по дням
  Future<Map<String, dynamic>> getChallengeDayProgress(
    String userId,
    String challengeId,
    DateTime startDate,
    int totalDays,
  ) async {
    return _challengeHabitRepository.getChallengeDayProgress(userId, challengeId, startDate, totalDays);
  }

  /// Получить стрим прогресса челленджа по дням
  Stream<Map<String, dynamic>> getChallengeDayProgressStream(
    String userId,
    String challengeId,
    DateTime startDate,
    int totalDays,
  ) {
    return _challengeHabitRepository.getChallengeDayProgressStream(userId, challengeId, startDate, totalDays);
  }

  /// Создать привычки челленджа при присоединении
  /// С проверкой на дубликаты - если привычка с таким названием уже есть, используем её
  Future<void> _createChallengeHabits(String userId, String challengeId, Map<String, dynamic> challenge) async {
    final habits = challenge['habits'] as List<dynamic>? ?? [];
    final habitRepository = HabitRepository();
    final challengeColor = challenge['color'] as Color? ?? AppColors.blue;
    
    // Получаем все существующие привычки пользователя для проверки дубликатов
    final existingHabits = await habitRepository.getUserHabitsFromServer(userId);
    
    for (int i = 0; i < habits.length; i++) {
      final habitData = habits[i] as Map<String, dynamic>;
      final habitTitle = habitData['title'] as String? ?? 'Habit ${i + 1}';
      final habitEmoji = habitData['icon'] as String? ?? '📝';
      final targetValue = habitData['targetValue'] as int? ?? 1;
      final targetUnit = habitData['targetUnit'] as String? ?? 'times';
      final incrementStep = habitData['incrementStep'] as int? ?? 1;
      final habitType = habitData['habitType'] as String? ?? 'build';
      
      // Проверяем, есть ли уже такая привычка у пользователя
      final existingHabit = existingHabits.where((h) => 
        h.name.toLowerCase().trim() == habitTitle.toLowerCase().trim() &&
        (h.challengeId == null || h.challengeId!.isEmpty) // Только обычные привычки, не из других челленджей
      ).firstOrNull;
      
      String habitId;
      
      if (existingHabit != null) {
        // Используем существующую привычку - обновляем её, добавляя challengeId
        print('[ChallengesService] Found existing habit: ${existingHabit.name}, linking to challenge');
        habitId = existingHabit.id!;
        
        // Обновляем привычку, добавляя challengeId
        final updatedHabit = existingHabit.copyWith(
          challengeId: challengeId,
          color: HabitModel.colorToHex(challengeColor), // Можно обновить цвет на цвет челленджа
        );
        await habitRepository.updateHabit(updatedHabit);
      } else {
        // Создаём новую привычку
        final habitModel = HabitModel(
          userId: userId,
          name: habitTitle,
          emoji: habitEmoji,
          color: HabitModel.colorToHex(challengeColor),
          habitType: habitType,
          targetValue: targetValue,
          targetUnit: targetUnit,
          incrementStep: incrementStep,
          frequency: 1,
          period: 'day',
          remindersEnabled: false,
          isDefaultHabit: false,
          challengeId: challengeId,
        );
        
        final createdHabit = await habitRepository.createHabit(habitModel);
        habitId = createdHabit.id!;
      }
      
      // Создаём связь в challenge_habits
      final challengeHabit = ChallengeHabitModel(
        userId: userId,
        challengeId: challengeId,
        habitId: habitId,
        name: habitTitle,
        emoji: habitEmoji,
        targetValue: targetValue,
        targetUnit: targetUnit,
        incrementStep: incrementStep,
        habitType: habitType,
      );
      await _challengeHabitRepository.createChallengeHabit(challengeHabit);
    }
  }

  /// Удалить привычки челленджа при выходе
  Future<void> _deleteChallengeHabits(String userId, String challengeId) async {
    // Получаем все привычки челленджа
    final challengeHabits = await _challengeHabitRepository.getUserChallengeHabitsFuture(userId, challengeId);
    final habitRepository = HabitRepository();
    
    // Удаляем реальные привычки из habits
    for (final ch in challengeHabits) {
      if (ch.habitId.isNotEmpty) {
        await habitRepository.deleteHabit(ch.habitId);
      }
    }
    
    // Удаляем записи из challenge_habits
    await _challengeHabitRepository.deleteAllChallengeHabits(userId, challengeId);
  }
}
