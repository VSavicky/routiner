import 'package:flutter/material.dart';

class DefaultHabit {
  final String id;
  final String name;
  final String emoji;
  final String subtitle;
  final Color color;
  final int targetValue;
  final String targetUnit;
  final String unitLabel;
  final int frequency;
  final String period;
  final bool isGoodHabit;
  final String? motivation;
  final String? reminderTime;

  const DefaultHabit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.subtitle,
    required this.color,
    required this.targetValue,
    required this.targetUnit,
    required this.unitLabel,
    this.frequency = 1,
    this.period = 'day',
    this.isGoodHabit = true,
    this.motivation,
    this.reminderTime,
  });
}

// Системные (предустановленные) привычки
class DefaultHabits {
  static const List<DefaultHabit> goodHabits = [
    DefaultHabit(
      id: 'walk',
      name: 'Walk',
      emoji: '🚶',
      subtitle: '10,000 steps',
      color: Color(0xFFFFB3BA),
      targetValue: 10000,
      targetUnit: 'steps',
      unitLabel: 'steps',
      motivation: 'Walking improves cardiovascular health and boosts mood',
      reminderTime: '08:00',
    ),
    DefaultHabit(
      id: 'read',
      name: 'Read',
      emoji: '📚',
      subtitle: '30 pages',
      color: Color(0xFFB3E5FC),
      targetValue: 30,
      targetUnit: 'pages',
      unitLabel: 'pages',
      motivation: 'Reading expands knowledge and reduces stress',
      reminderTime: '21:00',
    ),
    DefaultHabit(
      id: 'water',
      name: 'Drink Water',
      emoji: '💧',
      subtitle: '2,000 ml',
      color: Color(0xFFB3FFB3),
      targetValue: 2000,
      targetUnit: 'ml',
      unitLabel: 'ml',
      motivation: 'Staying hydrated improves energy and concentration',
      reminderTime: '09:00',
    ),
    DefaultHabit(
      id: 'meditate',
      name: 'Meditate',
      emoji: '🧘',
      subtitle: '15 min',
      color: Color(0xFFE5B3FF),
      targetValue: 15,
      targetUnit: 'min',
      unitLabel: 'min',
      motivation: 'Meditation reduces anxiety and improves focus',
    ),
    DefaultHabit(
      id: 'run',
      name: 'Run',
      emoji: '🏃',
      subtitle: '5 km',
      color: Color(0xFFFFD8B3),
      targetValue: 5,
      targetUnit: 'km',
      unitLabel: 'km',
      motivation: 'Running strengthens heart and builds endurance',
    ),
    DefaultHabit(
      id: 'sleep',
      name: 'Sleep Early',
      emoji: '😴',
      subtitle: '8 hours',
      color: Color(0xFFFFF4B3),
      targetValue: 8,
      targetUnit: 'hours',
      unitLabel: 'hours',
      motivation: 'Good sleep is essential for health and productivity',
    ),
    DefaultHabit(
      id: 'workout',
      name: 'Workout',
      emoji: '💪',
      subtitle: '45 min',
      color: Color(0xFFFFB3E5),
      targetValue: 45,
      targetUnit: 'min',
      unitLabel: 'min',
      motivation: 'Regular exercise keeps body strong and mind sharp',
    ),
    DefaultHabit(
      id: 'journal',
      name: 'Journal',
      emoji: '✍️',
      subtitle: '1 entry',
      color: Color(0xFFB3FFF4),
      targetValue: 1,
      targetUnit: 'times',
      unitLabel: 'times',
      motivation: 'Journaling helps process emotions and track growth',
    ),
  ];

  static const List<DefaultHabit> badHabits = [
    DefaultHabit(
      id: 'smoke',
      name: 'Quit Smoking',
      emoji: '🚭',
      subtitle: '0 cigarettes',
      color: Color(0xFFFFB3BA),
      targetValue: 0,
      targetUnit: 'times',
      unitLabel: 'cigarettes',
      isGoodHabit: false,
      motivation: 'Quitting smoking dramatically improves health',
    ),
    DefaultHabit(
      id: 'sugar',
      name: 'Less Sugar',
      emoji: '🍰',
      subtitle: 'Max 25g',
      color: Color(0xFFFFD8B3),
      targetValue: 25,
      targetUnit: 'cal',
      unitLabel: 'cal',
      isGoodHabit: false,
      motivation: 'Reducing sugar helps maintain healthy weight',
    ),
    DefaultHabit(
      id: 'social',
      name: 'Less Social Media',
      emoji: '📱',
      subtitle: 'Max 30 min',
      color: Color(0xFFB3E5FC),
      targetValue: 30,
      targetUnit: 'min',
      unitLabel: 'min',
      isGoodHabit: false,
      motivation: 'Less screen time means more real connections',
    ),
    DefaultHabit(
      id: 'alcohol',
      name: 'No Alcohol',
      emoji: '🍷',
      subtitle: '0 drinks',
      color: Color(0xFFE5B3FF),
      targetValue: 0,
      targetUnit: 'times',
      unitLabel: 'drinks',
      isGoodHabit: false,
      motivation: 'Avoiding alcohol improves sleep and liver health',
    ),
    DefaultHabit(
      id: 'procrastinate',
      name: 'Stop Procrastinating',
      emoji: '⏰',
      subtitle: 'Complete tasks',
      color: Color(0xFFFFF4B3),
      targetValue: 1,
      targetUnit: 'times',
      unitLabel: 'tasks',
      isGoodHabit: false,
      motivation: 'Taking action builds confidence and reduces stress',
    ),
  ];

  static DefaultHabit? getById(String id) {
    try {
      return [...goodHabits, ...badHabits].firstWhere((h) => h.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<DefaultHabit> getByType(bool isGoodHabit) {
    return isGoodHabit ? goodHabits : badHabits;
  }
}
