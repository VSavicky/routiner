import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit_model.dart';
import '../models/habit_log_model.dart';

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

  /// Получить все привычки пользователя
  Stream<List<HabitModel>> getUserHabits(String userId) {
    return _firestore
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .where('isArchived', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => HabitModel.fromFirestore(doc)).toList();
    });
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

  /// Отметить привычку как выполненную/невыполненную
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
}
