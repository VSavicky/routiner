import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit_model.dart';
import '../models/habit_log_model.dart';
import '../models/mood_model.dart';

/// Репозиторий для работы с привычками в Firestore
class HabitRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  HabitRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Получить текущего пользователя
  User? get currentUser => _auth.currentUser;

  /// Получить ID текущего пользователя
  String? get currentUserId => _auth.currentUser?.uid;

  /// Проверка авторизации
  bool get isAuthenticated => currentUser != null;

  // ==================== HABITS ====================

  /// Создать новую привычку
  Future<HabitModel> createHabit(HabitModel habit) async {
    try {
      final docRef = await _firestore.collection('habits').add(habit.toFirestore());
      return habit.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create habit: $e');
    }
  }

  /// Получить привычку по ID
  Future<HabitModel?> getHabitById(String habitId) async {
    try {
      final doc = await _firestore.collection('habits').doc(habitId).get();
      if (doc.exists) {
        return HabitModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get habit: $e');
    }
  }

  /// Получить все привычки пользователя (простой запрос без orderBy)
  Stream<List<HabitModel>> getUserHabits(String userId) {
    return _firestore
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final habits = snapshot.docs
          .map((doc) => HabitModel.fromFirestore(doc))
          .where((h) => !h.isArchived) // Фильтруем на клиенте
          .toList();
      // Сортируем на клиенте по createdAt (новые сначала)
      habits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return habits;
    });
  }
  
  /// Получить все привычки пользователя принудительно с сервера (без кэша)
  Future<List<HabitModel>> getUserHabitsFromServer(String userId) async {
    final snapshot = await _firestore
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .get(GetOptions(source: Source.server));
    final habits = snapshot.docs
        .map((doc) => HabitModel.fromFirestore(doc))
        .where((h) => !h.isArchived) // Фильтруем на клиенте
        .toList();
    // Сортируем на клиенте по createdAt (новые сначала)
    habits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return habits;
  }

  /// Получить архивированные привычки пользователя
  Stream<List<HabitModel>> getArchivedHabits(String userId) {
    return _firestore
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .where('isArchived', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => HabitModel.fromFirestore(doc)).toList();
    });
  }

  /// Обновить привычку
  Future<void> updateHabit(HabitModel habit) async {
    try {
      if (habit.id == null) {
        throw Exception('Habit ID is required for update');
      }
      await _firestore.collection('habits').doc(habit.id).update(
        habit.copyWith(updatedAt: DateTime.now()).toFirestore(),
      );
    } catch (e) {
      throw Exception('Failed to update habit: $e');
    }
  }

  /// Архивировать/разархивировать привычку
  Future<void> toggleArchiveHabit(String habitId, bool isArchived) async {
    try {
      await _firestore.collection('habits').doc(habitId).update({
        'isArchived': isArchived,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to archive habit: $e');
    }
  }

  /// Удалить привычку
  Future<void> deleteHabit(String habitId) async {
    try {
      // Удаляем привычку
      await _firestore.collection('habits').doc(habitId).delete();
      
      // Удаляем все логи этой привычки
      final logsQuery = await _firestore
          .collection('habitLogs')
          .where('habitId', isEqualTo: habitId)
          .get();
      
      final batch = _firestore.batch();
      for (var doc in logsQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete habit: $e');
    }
  }

  // ==================== HABIT LOGS ====================

  /// Обновить статус привычки (completed, skipped, failed)
  Future<HabitLogModel> updateHabitStatus(
    String habitId,
    DateTime date,
    HabitStatus status, {
    int? value,
    String? note,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final logId = HabitLogModel.createId(userId, habitId, date);
      final logRef = _firestore.collection('habitLogs').doc(logId);
      final doc = await logRef.get();

      final isCompleted = status == HabitStatus.completed;
      final completedAt = isCompleted ? DateTime.now() : null;

      if (doc.exists) {
        // Обновляем существующий лог
        final existingLog = HabitLogModel.fromFirestore(doc);
        final wasCompletedBefore = existingLog.status == HabitStatus.completed;
        
        final updatedLog = existingLog.copyWith(
          status: status,
          isCompleted: isCompleted,
          completedAt: completedAt,
          value: value ?? existingLog.value,
          note: note ?? existingLog.note,
        );
        await logRef.update(updatedLog.toFirestore());
        
        // Начисляем очки только если статус изменился на completed
        if (isCompleted && !wasCompletedBefore) {
          await addPoints(userId, 10);
        }
        
        return updatedLog;
      } else {
        // Создаем новый лог
        final newLog = HabitLogModel(
          id: logId,
          userId: userId,
          habitId: habitId,
          date: date,
          status: status,
          isCompleted: isCompleted,
          completedAt: completedAt,
          value: value,
          note: note,
        );
        await logRef.set(newLog.toFirestore());
        
        // Начисляем очки если статус completed
        if (isCompleted) {
          await addPoints(userId, 10);
        }
        
        return newLog;
      }
    } catch (e) {
      throw Exception('Failed to update habit status: $e');
    }
  }

  /// Добавить шаг выполнения привычки (инкремент value)
  Future<HabitLogModel> incrementHabitProgress(
    String habitId,
    DateTime date,
    int increment, {
    String? note,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final logId = HabitLogModel.createId(userId, habitId, date);
      final logRef = _firestore.collection('habitLogs').doc(logId);
      final doc = await logRef.get();

      // Получаем привычку для проверки targetValue
      final habitDoc = await _firestore.collection('habits').doc(habitId).get();
      final targetValue = habitDoc.exists 
          ? (habitDoc.data() as Map<String, dynamic>)['targetValue'] ?? 1 
          : 1;

      if (doc.exists) {
        // Обновляем существующий лог
        final existingLog = HabitLogModel.fromFirestore(doc);
        final newValue = (existingLog.value ?? 0) + increment;
        final isCompleted = newValue >= targetValue;
        
        final wasCompletedBefore = existingLog.isCompleted;
        
        final updatedLog = existingLog.copyWith(
          value: newValue,
          status: isCompleted ? HabitStatus.completed : existingLog.status,
          isCompleted: isCompleted,
          completedAt: isCompleted && !wasCompletedBefore 
              ? DateTime.now() 
              : existingLog.completedAt,
          note: note ?? existingLog.note,
        );
        await logRef.update(updatedLog.toFirestore());
        
        // Начисляем очки если привычка только что стала completed
        if (isCompleted && !wasCompletedBefore) {
          await addPoints(userId, 10);
        }
        
        return updatedLog;
      } else {
        // Создаем новый лог
        final isCompleted = increment >= targetValue;
        final newLog = HabitLogModel(
          id: logId,
          userId: userId,
          habitId: habitId,
          date: date,
          value: increment,
          status: isCompleted ? HabitStatus.completed : HabitStatus.pending,
          isCompleted: isCompleted,
          completedAt: isCompleted ? DateTime.now() : null,
          note: note,
        );
        await logRef.set(newLog.toFirestore());
        
        // Начисляем очки если привычка сразу выполнена
        if (isCompleted) {
          await addPoints(userId, 10);
        }
        
        return newLog;
      }
    } catch (e) {
      throw Exception('Failed to increment habit progress: $e');
    }
  }

  /// Отметить привычку как выполненную/невыполненную (legacy)
  Future<HabitLogModel> toggleHabitCompletion(
    String habitId,
    DateTime date, {
    int? value,
    String? note,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final logId = HabitLogModel.createId(userId, habitId, date);
      final logRef = _firestore.collection('habitLogs').doc(logId);
      final doc = await logRef.get();

      if (doc.exists) {
        // Обновляем существующий лог
        final existingLog = HabitLogModel.fromFirestore(doc);
        final updatedLog = existingLog.copyWith(
          isCompleted: !existingLog.isCompleted,
          completedAt: !existingLog.isCompleted ? DateTime.now() : null,
          value: value ?? existingLog.value,
          note: note ?? existingLog.note,
        );
        await logRef.update(updatedLog.toFirestore());
        return updatedLog;
      } else {
        // Создаем новый лог
        final newLog = HabitLogModel(
          id: logId,
          userId: userId,
          habitId: habitId,
          date: date,
          isCompleted: true,
          completedAt: DateTime.now(),
          value: value,
          note: note,
        );
        await logRef.set(newLog.toFirestore());
        return newLog;
      }
    } catch (e) {
      throw Exception('Failed to toggle habit completion: $e');
    }
  }

  /// Получить логи привычки за период
  Stream<List<HabitLogModel>> getHabitLogsForPeriod(
    String habitId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestore
        .collection('habitLogs')
        .where('habitId', isEqualTo: habitId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => HabitLogModel.fromFirestore(doc)).toList();
    });
  }

  /// Получить лог за конкретную дату
  Future<HabitLogModel?> getHabitLogForDate(String habitId, DateTime date) async {
    try {
      final userId = currentUserId;
      if (userId == null) return null;

      final logId = HabitLogModel.createId(userId, habitId, date);
      final doc = await _firestore.collection('habitLogs').doc(logId).get();
      
      if (doc.exists) {
        return HabitLogModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get habit log: $e');
    }
  }

  /// Получить логи привычек за дату (фильтруем на клиенте для избежания индексов)
  Future<List<HabitLogModel>> getHabitLogsForDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // Получаем все логи пользователя и фильтруем на клиенте (не требует индекса)
      final snapshot = await _firestore
          .collection('habitLogs')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => HabitLogModel.fromFirestore(doc))
          .where((log) {
            final logDate = log.date;
            return logDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
                   logDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
          })
          .toList();
    } catch (e) {
      print('Error getting habit logs: $e');
      return [];
    }
  }

  /// Получить логи привычек за дату принудительно с сервера (без кэша)
  Future<List<HabitLogModel>> getHabitLogsForDateFromServer(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // Получаем все логи пользователя с сервера и фильтруем на клиенте
      final snapshot = await _firestore
          .collection('habitLogs')
          .where('userId', isEqualTo: userId)
          .get(GetOptions(source: Source.server));

      return snapshot.docs
          .map((doc) => HabitLogModel.fromFirestore(doc))
          .where((log) {
            final logDate = log.date;
            return logDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
                   logDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
          })
          .toList();
    } catch (e) {
      print('Error getting habit logs from server: $e');
      return [];
    }
  }

  /// Получить статистику по привычке
  Future<Map<String, dynamic>> getHabitStats(String habitId, DateTime fromDate) async {
    try {
      final logs = await _firestore
          .collection('habitLogs')
          .where('habitId', isEqualTo: habitId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate))
          .where('isCompleted', isEqualTo: true)
          .get();

      final totalCompleted = logs.docs.length;
      final totalDays = DateTime.now().difference(fromDate).inDays + 1;
      final completionRate = totalDays > 0 ? totalCompleted / totalDays : 0.0;

      // Вычисляем streak (подряд выполненных дней)
      int currentStreak = 0;
      DateTime checkDate = DateTime.now();
      
      while (true) {
        final logId = HabitLogModel.createId(
          currentUserId ?? '',
          habitId,
          checkDate,
        );
        final doc = await _firestore.collection('habitLogs').doc(logId).get();
        
        if (doc.exists && (doc.data() as Map<String, dynamic>)['isCompleted'] == true) {
          currentStreak++;
          checkDate = checkDate.subtract(Duration(days: 1));
        } else {
          break;
        }
      }

      return {
        'totalCompleted': totalCompleted,
        'totalDays': totalDays,
        'completionRate': completionRate,
        'currentStreak': currentStreak,
      };
    } catch (e) {
      throw Exception('Failed to get habit stats: $e');
    }
  }

  // ==================== BATCH OPERATIONS ====================

  /// Создать несколько привычек за один batch (для дефолтных привычек)
  Future<List<HabitModel>> createHabitsBatch(List<HabitModel> habits) async {
    try {
      final batch = _firestore.batch();
      final createdHabits = <HabitModel>[];

      for (var habit in habits) {
        final docRef = _firestore.collection('habits').doc();
        batch.set(docRef, habit.copyWith(id: docRef.id).toFirestore());
        createdHabits.add(habit.copyWith(id: docRef.id));
      }

      await batch.commit();
      return createdHabits;
    } catch (e) {
      throw Exception('Failed to create habits batch: $e');
    }
  }

  // ==================== МЕТОДЫ ДЛЯ РАБОТЫ С НАСТРОЕНИЕМ ====================

  /// Сохранить настроение пользователя
  Future<MoodModel> saveMood({
    required String userId,
    required String emoji,
    required String label,
    required DateTime date,
  }) async {
    try {
      // Проверяем, есть ли уже настроение за эту дату
      final existingMood = await getMoodForDate(userId, date);
      
      final mood = MoodModel(
        id: existingMood?.id,
        userId: userId,
        emoji: emoji,
        label: label,
        date: date,
      );

      if (existingMood?.id != null) {
        // Обновляем существующее
        await _firestore
            .collection('moods')
            .doc(existingMood!.id)
            .update(mood.toFirestore());
      } else {
        // Создаем новое
        final docRef = await _firestore
            .collection('moods')
            .add(mood.toFirestore());
        return mood.copyWith(id: docRef.id);
      }

      return mood;
    } catch (e) {
      throw Exception('Failed to save mood: $e');
    }
  }

  /// Получить настроение за конкретную дату
  Future<MoodModel?> getMoodForDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('moods')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return MoodModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('Error getting mood for date: $e');
      return null;
    }
  }

  /// Получить стрим настроений пользователя
  Stream<List<MoodModel>> getUserMoods(String userId) {
    return _firestore
        .collection('moods')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MoodModel.fromFirestore(doc)).toList();
    });
  }

  /// Удалить настроение
  Future<void> deleteMood(String moodId) async {
    try {
      await _firestore.collection('moods').doc(moodId).delete();
    } catch (e) {
      throw Exception('Failed to delete mood: $e');
    }
  }

  /// Добавить очки пользователю (система вознаграждения)
  Future<void> addPoints(String userId, int points) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      
      if (userDoc.exists) {
        // Обновляем существующие очки
        final currentPoints = (userDoc.data()?['points'] ?? 0) as int;
        await userRef.update({'points': currentPoints + points});
      } else {
        // Создаем документ с очками
        await userRef.set({
          'points': points,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error adding points: $e');
      throw Exception('Failed to add points: $e');
    }
  }

  /// Получить текущие очки пользователя
  Future<int> getUserPoints(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return (userDoc.data()?['points'] ?? 0) as int;
      }
      return 0;
    } catch (e) {
      print('Error getting user points: $e');
      return 0;
    }
  }
}
