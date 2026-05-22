import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/challenge_habit_model.dart';

/// Репозиторий для работы с привычками челленджа в Firestore
class ChallengeHabitRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ChallengeHabitRepository({
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

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isFutureDate(DateTime date) {
    return _dateOnly(date).isAfter(_dateOnly(DateTime.now()));
  }

  // ==================== CHALLENGE HABITS ====================

  /// Создать привычку челленджа
  Future<ChallengeHabitModel> createChallengeHabit(ChallengeHabitModel habit) async {
    try {
      final docRef = await _firestore.collection('challenge_habits').add(habit.toFirestore());
      return habit.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create challenge habit: $e');
    }
  }

  /// Получить все привычки челленджа пользователя
  Stream<List<ChallengeHabitModel>> getUserChallengeHabits(String userId, String challengeId) {
    return _firestore
        .collection('challenge_habits')
        .where('userId', isEqualTo: userId)
        .where('challengeId', isEqualTo: challengeId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChallengeHabitModel.fromFirestore(doc)).toList();
    });
  }

  /// Получить все привычки челленджа пользователя (Future)
  Future<List<ChallengeHabitModel>> getUserChallengeHabitsFuture(String userId, String challengeId) async {
    final snapshot = await _firestore
        .collection('challenge_habits')
        .where('userId', isEqualTo: userId)
        .where('challengeId', isEqualTo: challengeId)
        .get();
    return snapshot.docs.map((doc) => ChallengeHabitModel.fromFirestore(doc)).toList();
  }

  /// Получить привычку челленджа по ID
  Future<ChallengeHabitModel?> getChallengeHabitById(String habitId) async {
    try {
      final doc = await _firestore.collection('challenge_habits').doc(habitId).get();
      if (doc.exists) {
        return ChallengeHabitModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get challenge habit: $e');
    }
  }

  /// Обновить привычку челленджа
  Future<void> updateChallengeHabit(ChallengeHabitModel habit) async {
    try {
      if (habit.id == null) {
        throw Exception('Cannot update habit without id');
      }
      await _firestore.collection('challenge_habits').doc(habit.id).update(habit.toFirestore());
    } catch (e) {
      throw Exception('Failed to update challenge habit: $e');
    }
  }

  /// Удалить привычку челленджа
  Future<void> deleteChallengeHabit(String habitId) async {
    try {
      await _firestore.collection('challenge_habits').doc(habitId).delete();
    } catch (e) {
      throw Exception('Failed to delete challenge habit: $e');
    }
  }

  /// Удалить все привычки челленджа при выходе из челленджа
  Future<void> deleteAllChallengeHabits(String userId, String challengeId) async {
    try {
      final snapshot = await _firestore
          .collection('challenge_habits')
          .where('userId', isEqualTo: userId)
          .where('challengeId', isEqualTo: challengeId)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete challenge habits: $e');
    }
  }

  /// Получить статистику выполнения привычек челленджа (Future)
  Future<Map<String, dynamic>> getChallengeStats(String userId, String challengeId) async {
    try {
      final habits = await getUserChallengeHabitsFuture(userId, challengeId);
      
      int totalHabits = habits.length;
      int completedHabits = habits.where((h) => h.isCompleted).length;
      double progress = totalHabits > 0 ? completedHabits / totalHabits : 0;
      
      return {
        'totalHabits': totalHabits,
        'completedHabits': completedHabits,
        'progress': progress,
        'progressPercent': (progress * 100).round(),
      };
    } catch (e) {
      return {
        'totalHabits': 0,
        'completedHabits': 0,
        'progress': 0.0,
        'progressPercent': 0,
      };
    }
  }

  /// Получить статистику челленджа в реальном времени (Stream)
  /// Проверяет логи привычек для указанной даты
  Stream<Map<String, dynamic>> getChallengeStatsStream(
    String userId,
    String challengeId, {
    DateTime? date,
  }) {
    return _firestore
        .collection('challenge_habits')
        .where('userId', isEqualTo: userId)
        .where('challengeId', isEqualTo: challengeId)
        .snapshots()
        .asyncMap((snapshot) async {
      try {
        final habits = snapshot.docs.map((doc) => ChallengeHabitModel.fromFirestore(doc)).toList();
        
        if (habits.isEmpty) {
          return {
            'totalHabits': 0,
            'completedHabits': 0,
            'progress': 0.0,
            'progressPercent': 0,
          };
        }

        int completedCount = 0;
        final targetDate = date ?? DateTime.now();
        final dateStr = '${targetDate.year}${targetDate.month.toString().padLeft(2, '0')}${targetDate.day.toString().padLeft(2, '0')}';

        // Проверяем логи для каждой привычки
        for (final habit in habits) {
          if (habit.habitId.isEmpty) continue;
          
          // Проверяем сегодняшний лог - используем тот же формат ID что и в HabitLogModel.createId
          final logId = '${userId}_${habit.habitId}_$dateStr';
          final logDoc = await _firestore.collection('habitLogs').doc(logId).get();
          
          if (logDoc.exists) {
            final data = logDoc.data() as Map<String, dynamic>;
            final isCompleted = data['isCompleted'] ?? false;
            final status = data['status'] ?? 'pending';
            final value = data['value'] ?? 0;
            final targetValue = habit.targetValue;
            
            // Привычка выполнена если статус completed ИЛИ value >= targetValue
            if (isCompleted || status == 'completed' || value >= targetValue) {
              completedCount++;
            }
          }
        }

        final totalHabits = habits.length;
        final progress = totalHabits > 0 ? completedCount / totalHabits : 0.0;
        final isDayCompleted = totalHabits > 0 && completedCount >= totalHabits;
        
        // Если все привычки выполнены - отмечаем день как завершенный
        if (isDayCompleted && !_isFutureDate(targetDate)) {
          try {
            final dateStr = targetDate.toIso8601String().split('T')[0];
            final docId = '${userId}_${challengeId}_$dateStr';
            
            // Проверяем не отмечен ли уже
            final progressDoc = await _firestore.collection('challengeProgress').doc(docId).get();
            if (!progressDoc.exists || !(progressDoc.data()?['isCompleted'] ?? false)) {
              // Отмечаем день как завершенный
              await _firestore.collection('challengeProgress').doc(docId).set({
                'userId': userId,
                'challengeId': challengeId,
                'date': dateStr,
                'isCompleted': true,
                'completedAt': Timestamp.fromDate(DateTime.now()),
              });
              print('[ChallengeHabitRepository] Day $dateStr marked as completed for challenge $challengeId');
            }
          } catch (e) {
            print('[ChallengeHabitRepository] Error marking day completed: $e');
          }
        }

        return {
          'totalHabits': totalHabits,
          'completedHabits': completedCount,
          'progress': progress,
          'progressPercent': (progress * 100).round(),
          'isDayCompleted': isDayCompleted,
        };
      } catch (e) {
        print('[ChallengeHabitRepository] Error getting stats: $e');
        return {
          'totalHabits': 0,
          'completedHabits': 0,
          'progress': 0.0,
          'progressPercent': 0,
          'isDayCompleted': false,
        };
      }
    });
  }

  /// Отметить день челленджа как завершенный (все привычки выполнены)
  Future<void> markChallengeDayCompleted(
    String userId,
    String challengeId,
    DateTime date,
  ) async {
    try {
      if (_isFutureDate(date)) {
        throw Exception('Cannot mark challenge day completed for future dates');
      }

      final dateStr = date.toIso8601String().split('T')[0];
      final docId = '${userId}_${challengeId}_$dateStr';
      
      await _firestore.collection('challengeProgress').doc(docId).set({
        'userId': userId,
        'challengeId': challengeId,
        'date': dateStr,
        'isCompleted': true,
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('[ChallengeHabitRepository] Error marking day completed: $e');
    }
  }

  /// Получить прогресс челленджа по дням (сколько дней завершено)
  Future<Map<String, dynamic>> getChallengeDayProgress(
    String userId,
    String challengeId,
    DateTime startDate,
    int totalDays,
  ) async {
    try {
      final now = DateTime.now();
      final completedDays = <String>[];
      int completedCount = 0;
      
      // Проверяем каждый день челленджа
      for (int i = 0; i < totalDays; i++) {
        final checkDate = startDate.add(Duration(days: i));
        if (checkDate.isAfter(now)) break; // Не проверяем будущие даты
        
        final dateStr = checkDate.toIso8601String().split('T')[0];
        final docId = '${userId}_${challengeId}_$dateStr';
        
        final doc = await _firestore.collection('challengeProgress').doc(docId).get();
        if (doc.exists && (doc.data()?['isCompleted'] ?? false)) {
          completedDays.add(dateStr);
          completedCount++;
        }
      }
      
      return {
        'completedDays': completedDays,
        'completedCount': completedCount,
        'totalDays': totalDays,
        'progressPercent': totalDays > 0 ? (completedCount / totalDays * 100).round() : 0,
        'isFullyCompleted': completedCount >= totalDays,
      };
    } catch (e) {
      print('[ChallengeHabitRepository] Error getting day progress: $e');
      return {
        'completedDays': [],
        'completedCount': 0,
        'totalDays': totalDays,
        'progressPercent': 0,
        'isFullyCompleted': false,
      };
    }
  }

  /// Получить стрим прогресса челленджа по дням
  Stream<Map<String, dynamic>> getChallengeDayProgressStream(
    String userId,
    String challengeId,
    DateTime startDate,
    int totalDays,
  ) {
    return _firestore
        .collection('challengeProgress')
        .where('userId', isEqualTo: userId)
        .where('challengeId', isEqualTo: challengeId)
        .where('isCompleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      try {
        final completedDays = snapshot.docs
            .map((d) => d.data()['date'] as String?)
            .where((d) => d != null)
            .cast<String>()
            .toList();
        
        final completedCount = completedDays.length;
        
        return {
          'completedDays': completedDays,
          'completedCount': completedCount,
          'totalDays': totalDays,
          'progressPercent': totalDays > 0 ? (completedCount / totalDays * 100).round() : 0,
          'isFullyCompleted': completedCount >= totalDays,
        };
      } catch (e) {
        return {
          'completedDays': [],
          'completedCount': 0,
          'totalDays': totalDays,
          'progressPercent': 0,
          'isFullyCompleted': false,
        };
      }
    });
  }
}
