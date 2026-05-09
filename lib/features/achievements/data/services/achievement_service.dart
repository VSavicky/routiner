import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routiner/features/achievements/data/models/achievement_model.dart';
import 'package:routiner/features/achievements/data/repositories/achievement_repository.dart';

class AchievementService {
  final AchievementRepository _achievementRepository = AchievementRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Проверить и выдать достижения за очки
  Future<void> checkAndAwardPointsAchievements(String userId) async {
    try {
      final points = await _calculateTotalPoints(userId);
      
      // Достижения за очки
      if (points >= 100) {
        await _awardIfNotExists(userId, 'First Steps', () async { 
          return _achievementRepository.createAchievement(
            userId: userId,
            title: 'First Steps',
            description: 'Earn your first 100 points',
            icon: '🌟',
            type: AchievementType.points,
          );
        });
      }
      
      if (points >= 500) {
        await _awardIfNotExists(userId, 'Rising Star', () async { 
          return _achievementRepository.createAchievement(
            userId: userId,
            title: 'Rising Star',
            description: 'Earn 500 points',
            icon: '⭐',
            type: AchievementType.points,
          );
        });
      }
      
      if (points >= 1000) {
        await _awardIfNotExists(userId, 'Point Master', () async { 
          return _achievementRepository.createAchievement(
            userId: userId,
            title: 'Point Master',
            description: 'Earn 1000 points',
            icon: '🏆',
            type: AchievementType.points,
          );
        });
      }
    } catch (e) {
      print('[ACHIEVEMENT SERVICE ERROR] Failed to check points achievements: $e');
    }
  }

  // Проверить и выдать достижения за серии
  Future<void> checkAndAwardStreakAchievements(String userId) async {
    try {
      final streak = await _calculateBestStreak(userId);
      
      if (streak >= 7) {
        await _awardIfNotExists(userId, 'Week Warrior', () async { 
          return _achievementRepository.createAchievement(
            userId: userId,
            title: 'Week Warrior',
            description: 'Maintain a 7-day streak',
            icon: '🔥',
            type: AchievementType.streak,
          );
        });
      }
      
      if (streak >= 30) {
        await _awardIfNotExists(userId, 'Monthly Champion', () async { 
          return _achievementRepository.createAchievement(
            userId: userId,
            title: 'Monthly Champion',
            description: 'Maintain a 30-day streak',
            icon: '💪',
            type: AchievementType.streak,
          );
        });
      }
    } catch (e) {
      print('[ACHIEVEMENT SERVICE ERROR] Failed to check streak achievements: $e');
    }
  }

  // Выдать достижение за вступление в клуб
  Future<void> awardClubAchievement(String userId, String clubName) async {
    try {
      final clubAchievements = await _achievementRepository.getUserAchievements(userId);
      final clubCount = clubAchievements
          .where((a) => a.type == AchievementType.club)
          .length;
      
      if (clubCount == 0) {
        // Первое достижение за клуб
        await _awardIfNotExists(userId, 'Club Member', () async {
          return _achievementRepository.createAchievement(
            userId: userId,
            title: 'Club Member',
            description: 'Join your first club',
            icon: '👥',
            type: AchievementType.club,
            metadata: {'clubName': clubName},
          );
        });
      } else if (clubCount == 4) {
        // Достижение за 5 клубов
        await _awardIfNotExists(userId, 'Social Butterfly', () async { 
          return _achievementRepository.createAchievement(
            userId: userId,
            title: 'Social Butterfly',
            description: 'Join 5 clubs',
            icon: '🦋',
            type: AchievementType.club,
          );
        });
      }
    } catch (e) {
      print('[ACHIEVEMENT SERVICE ERROR] Failed to award club achievement: $e');
    }
  }

  // Выдать достижение за выполнение челленджа
  Future<void> awardChallengeAchievement(String userId, String challengeTitle) async {
    try {
      await _awardIfNotExists(userId, challengeTitle, () async { 
        return _achievementRepository.createAchievement(
          userId: userId,
          title: challengeTitle,
          description: 'Complete challenge: $challengeTitle',
          icon: '🏅',
          type: AchievementType.challenge,
          metadata: {'challengeTitle': challengeTitle},
        );
      });
    } catch (e) {
      print('[ACHIEVEMENT SERVICE ERROR] Failed to award challenge achievement: $e');
    }
  }

  // Вспомогательный метод для выдачи достижения если его еще нет
  Future<void> _awardIfNotExists(String userId, String title, Future<AchievementModel> Function() createAchievement) async {
    // Используем проверку по названию для предотвращения дубликатов
    final hasAchievement = await _achievementRepository.hasAchievementByTitle(userId, title);
    if (!hasAchievement) {
      final achievement = await createAchievement();
      await _achievementRepository.awardAchievement(achievement);
      print('[ACHIEVEMENT DEBUG] Awarded new achievement: $title to user: $userId');
    } else {
      print('[ACHIEVEMENT DEBUG] Achievement already exists: $title for user: $userId - skipping');
    }
  }

  // Рассчитать общее количество очков пользователя
  Future<int> _calculateTotalPoints(String userId) async {
    try {
      final logsQuery = await _firestore
          .collection('habitLogs')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      return logsQuery.docs.length * 10; // 10 очков за каждую выполненную привычку
    } catch (e) {
      print('[ACHIEVEMENT SERVICE ERROR] Failed to calculate total points: $e');
      return 0;
    }
  }

  // Рассчитать лучшую серию пользователя
  Future<int> _calculateBestStreak(String userId) async {
    try {
      // Получаем все выполненные привычки пользователя
      final completedHabitsQuery = await _firestore
          .collection('habitLogs')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .orderBy('date', descending: true)
          .get();
      
      if (completedHabitsQuery.docs.isEmpty) {
        print('[ACHIEVEMENT DEBUG] No completed habits found for streak calculation');
        return 0;
      }
      
      // Рассчитываем реальную серию
      final completedHabits = completedHabitsQuery.docs
          .map((doc) => doc.data() as Map<String, dynamic>?)
          .toList();
      
      // Сортируем по дате
      completedHabits.sort((a, b) {
        final dateA = (a?['date'] as Timestamp?)?.toDate() ?? DateTime.now();
        final dateB = (b?['date'] as Timestamp?)?.toDate() ?? DateTime.now();
        return dateA.compareTo(dateB);
      });
      
      // Рассчитываем серию
      int currentStreak = 0;
      int bestStreak = 0;
      int tempStreak = 0;
      
      for (int i = 0; i < completedHabits.length; i++) {
        final currentDate = (completedHabits[i]?['date'] as Timestamp?)?.toDate() ?? DateTime.now();
        
        if (i == 0) {
          // Первый день - начинаем серию
          tempStreak = 1;
        } else {
          final previousDate = (completedHabits[i-1]?['date'] as Timestamp?)?.toDate() ?? DateTime.now();
          final difference = currentDate.difference(previousDate).inDays;
          
          if (difference == 1) {
            // Последовательный день
            tempStreak++;
          } else {
            // Пропуск - сбрасываем серию
            if (tempStreak > bestStreak) {
              bestStreak = tempStreak;
            }
            tempStreak = 1; // Начинаем новую серию
          }
        }
      }
      
      // Проверяем последнюю серию
      if (tempStreak > bestStreak) {
        bestStreak = tempStreak;
      }
      
      print('[ACHIEVEMENT DEBUG] Calculated streak - current: $tempStreak, best: $bestStreak');
      return bestStreak;
    } catch (e) {
      print('[ACHIEVEMENT SERVICE ERROR] Failed to calculate best streak: $e');
      return 0;
    }
  }

  // Проверка и выдача достижения за первую выполненную привычку
  Future<void> checkAndAwardFirstHabitAchievement(String userId) async {
    try {
      print('[ACHIEVEMENT DEBUG] Checking first habit achievement for user: $userId');
      
      // ДВУКРАТНАЯ ПРОВЕРКА - по названию и прямым запросом
      final hasFirstHabitByTitle = await _achievementRepository.hasAchievementByTitle(userId, 'First Habit');
      
      // Прямой запрос для надежности
      final directQuery = await _firestore
          .collection('achievements')
          .where('userId', isEqualTo: userId)
          .where('title', isEqualTo: 'First Habit')
          .get();
      
      final hasFirstHabitDirect = directQuery.docs.isNotEmpty;
      
      print('[ACHIEVEMENT DEBUG] Has First Habit by title: $hasFirstHabitByTitle');
      print('[ACHIEVEMENT DEBUG] Has First Habit direct: $hasFirstHabitDirect');
      
      if (hasFirstHabitByTitle || hasFirstHabitDirect) {
        print('[ACHIEVEMENT DEBUG] User already has First Habit achievement - skipping');
        return;
      }
      
      // Проверяем все habitLogs пользователя для отладки
      print('[ACHIEVEMENT DEBUG] Checking all habit logs for user: $userId');
      final allLogsQuery = await _firestore
          .collection('habitLogs')
          .where('userId', isEqualTo: userId)
          .get();
      
      print('[ACHIEVEMENT DEBUG] Total habit logs found: ${allLogsQuery.docs.length}');
      
      // Логируем все статусы привычек
      for (var doc in allLogsQuery.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final status = data?['status'] ?? 'unknown';
        final habitName = data?['habitName'] ?? 'unknown';
        final date = data?['date'] as Timestamp?;
        print('[ACHIEVEMENT DEBUG] Habit log: $habitName - status: $status - date: $date');
      }
      
      // Проверяем есть ли выполненные привычки
      final habitLogsQuery = await _firestore
          .collection('habitLogs')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();
      
      print('[ACHIEVEMENT DEBUG] Found ${habitLogsQuery.docs.length} completed habits for user');
      
      if (habitLogsQuery.docs.isNotEmpty) {
        // Сортируем на клиенте по дате (самая ранняя первая)
        final sortedDocs = habitLogsQuery.docs.toList();
        sortedDocs.sort((a, b) {
          final dateA = (a.data()['date'] as Timestamp?)?.toDate() ?? DateTime.now();
          final dateB = (b.data()['date'] as Timestamp?)?.toDate() ?? DateTime.now();
          return dateA.compareTo(dateB);
        });
        
        final firstHabit = sortedDocs.first;
        final habitData = firstHabit.data() as Map<String, dynamic>?;
        final habitName = habitData?['habitName'] ?? 'Unknown habit';
        final completedDate = (habitData?['date'] as Timestamp?)?.toDate() ?? DateTime.now();
        
        print('[ACHIEVEMENT DEBUG] First completed habit: $habitName at $completedDate');
        
        // ФИНАЛЬНАЯ ПРОВЕРКА - получаем все достижения пользователя
        final allUserAchievements = await _achievementRepository.getUserAchievements(userId);
        print('[ACHIEVEMENT DEBUG] User currently has ${allUserAchievements.length} achievements');
        
        // Проверяем по названию и ID
        final hasFirstHabitByName = allUserAchievements.any((a) => a.title == 'First Habit');
        final hasFirstHabitById = allUserAchievements.any((a) => a.id == 'first_habit');
        
        print('[ACHIEVEMENT DEBUG] Has First Habit by name: $hasFirstHabitByName');
        print('[ACHIEVEMENT DEBUG] Has First Habit by ID: $hasFirstHabitById');
        
        if (hasFirstHabitByName || hasFirstHabitById) {
          print('[ACHIEVEMENT DEBUG] User already has First Habit achievement - SKIPPING AWARD');
          return;
        }
        
        // Выдаем достижение за ПЕРВУЮ выполненную привычку
        final achievement = _achievementRepository.createAchievement(
          userId: userId,
          title: 'First Habit',
          description: 'Complete your first habit',
          icon: '🌟',
          type: AchievementType.points,
          achievementId: 'first_habit',
          metadata: {
            'habitName': habitName,
            'completedDate': completedDate.toIso8601String(),
          },
        );
        
        await _achievementRepository.awardAchievement(achievement);
        print('[ACHIEVEMENT] First habit achievement awarded to user: $userId');
        
        // Принудительное обновление кэша достижений
        print('[ACHIEVEMENT DEBUG] Clearing achievement cache for user: $userId');
        // Здесь можно добавить логику для очистки кэша если она есть
      } else {
        print('[ACHIEVEMENT DEBUG] No completed habits found for user: $userId');
      }
    } catch (e) {
      print('[ACHIEVEMENT SERVICE ERROR] Failed to check first habit achievement: $e');
    }
  }

  // Проверка и выдача достижения за любую выполненную привычку (для 5+ привычек)
  Future<void> checkAndAwardAnyHabitAchievement(String userId) async {
    try {
      print('[ACHIEVEMENT DEBUG] Checking any habit achievement for user: $userId');
      
      // ДВУКРАТНАЯ ПРОВЕРКА - по названию и прямым запросом
      final hasAchievementByTitle = await _achievementRepository.hasAchievementByTitle(userId, 'Habit Master');
      
      // Прямой запрос для надежности
      final directQuery = await _firestore
          .collection('achievements')
          .where('userId', isEqualTo: userId)
          .where('title', isEqualTo: 'Habit Master')
          .get();
      
      final hasAchievementDirect = directQuery.docs.isNotEmpty;
      
      print('[ACHIEVEMENT DEBUG] Has Habit Master by title: $hasAchievementByTitle');
      print('[ACHIEVEMENT DEBUG] Has Habit Master direct: $hasAchievementDirect');
      
      if (hasAchievementByTitle || hasAchievementDirect) {
        print('[ACHIEVEMENT DEBUG] User already has Habit Master achievement - skipping');
        return;
      }
      
      // Получаем все выполненные привычки пользователя
      final habitLogsQuery = await _firestore
          .collection('habitLogs')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();
      
      print('[ACHIEVEMENT DEBUG] Found ${habitLogsQuery.docs.length} completed habits for user');
      
      // Выдаем достижение если выполнено 5+ привычек
      if (habitLogsQuery.docs.length >= 5) {
        // Сортируем на клиенте по дате (самая последняя первая)
        final sortedDocs = habitLogsQuery.docs.toList();
        sortedDocs.sort((a, b) {
          final dateA = (a.data()['date'] as Timestamp?)?.toDate() ?? DateTime.now();
          final dateB = (b.data()['date'] as Timestamp?)?.toDate() ?? DateTime.now();
          return dateB.compareTo(dateA);
        });
        
        final lastHabit = sortedDocs.first;
        final habitData = lastHabit.data() as Map<String, dynamic>?;
        final habitName = habitData?['habitName'] ?? 'Unknown habit';
        final completedDate = (habitData?['date'] as Timestamp?)?.toDate() ?? DateTime.now();
        
        print('[ACHIEVEMENT DEBUG] Awarding Habit Master for 5+ habits: $habitName at $completedDate');
        
        // Выдаем достижение за выполненные привычки
        final achievement = _achievementRepository.createAchievement(
          userId: userId,
          title: 'Habit Master',
          description: 'Complete any habit',
          icon: '✅',
          type: AchievementType.points,
          achievementId: 'any_habit',
          metadata: {
            'habitName': habitName,
            'completedDate': completedDate.toIso8601String(),
          },
        );
        
        await _achievementRepository.awardAchievement(achievement);
        print('[ACHIEVEMENT] Any habit achievement awarded to user: $userId');
      } else {
        print('[ACHIEVEMENT DEBUG] User has less than 5 completed habits - no Habit Master yet');
      }
    } catch (e) {
      print('[ACHIEVEMENT SERVICE ERROR] Failed to check any habit achievement: $e');
    }
  }

  // Периодическая проверка достижений
  Future<void> periodicAchievementCheck() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await checkAndAwardPointsAchievements(user.uid);
      await checkAndAwardStreakAchievements(user.uid);
      await checkAndAwardFirstHabitAchievement(user.uid);
      await checkAndAwardAnyHabitAchievement(user.uid);
    }
  }
}
