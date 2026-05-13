import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routiner/features/habits/domain/entities/habit_entity.dart';
import 'package:routiner/l10n/app_localizations.dart';

class HabitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Создание новой привычки
  Future<void> createHabit({
    required String userId,
    required String name,
    required String emoji,
  }) async {
    final habit = HabitEntity(
      id: _firestore.collection('habits').doc().id,
      userId: userId,
      name: name,
      emoji: emoji,
      days: [],
    );

    await _firestore.collection('habits').doc(habit.id).set(habit.toMap());
  }

  // Получение всех привычек пользователя
  Future<List<HabitEntity>> getUserHabits(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('habits')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => HabitEntity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting user habits: $e');
      return [];
    }
  }

  // Отметка выполнения привычки на сегодня
  Future<void> markHabitCompleted({
    required String habitId,
    required String userId,
  }) async {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      final habitDoc = await _firestore.collection('habits').doc(habitId).get();
      if (!habitDoc.exists) return;

      final habit = HabitEntity.fromMap(habitDoc.data() as Map<String, dynamic>);
      
      // Находим или создаем запись для сегодня
      int todayIndex = -1;
      for (int i = 0; i < habit.days.length; i++) {
        if (habit.days[i].date == todayString) {
          todayIndex = i;
          break;
        }
      }

      final updatedDays = List<HabitDayEntity>.from(habit.days);
      
      if (todayIndex != -1) {
        // Обновляем существующий день
        updatedDays[todayIndex] = HabitDayEntity(
          date: todayString,
          isCompleted: !updatedDays[todayIndex].isCompleted,
          streak: updatedDays[todayIndex].isCompleted 
              ? updatedDays[todayIndex].streak + 1 
              : 0,
        );
      } else {
        // Добавляем новый день
        updatedDays.add(HabitDayEntity(
          date: todayString,
          isCompleted: true,
          streak: 1,
        ));
      }

      // Обновляем привычку в Firestore
      await _firestore.collection('habits').doc(habitId).update({
        'days': updatedDays.map((day) => day.toMap()).toList(),
      });
    } catch (e) {
      print('Error marking habit completed: $e');
    }
  }

  // Получение статистики по привычкам
  Future<Map<String, dynamic>> getHabitStats(String userId) async {
    try {
      final habits = await getUserHabits(userId);
      
      int totalHabits = habits.length;
      int completedToday = 0;
      int currentStreak = 0;
      
      for (final habit in habits) {
        final today = DateTime.now();
        final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        
        int todayIndex = -1;
        for (int i = 0; i < habit.days.length; i++) {
          if (habit.days[i].date == todayString) {
            todayIndex = i;
            break;
          }
        }
        
        if (todayIndex != -1 && habit.days[todayIndex].isCompleted) {
          completedToday++;
          currentStreak = habit.days[todayIndex].streak;
        }
      }

      return {
        'totalHabits': totalHabits,
        'completedToday': completedToday,
        'currentStreak': currentStreak,
        'completionRate': totalHabits > 0 ? (completedToday / totalHabits) * 100 : 0,
      };
    } catch (e) {
      print('Error getting habit stats: $e');
      return {
        'totalHabits': 0,
        'completedToday': 0,
        'currentStreak': 0,
        'completionRate': 0,
      };
    }
  }
}
