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
      name: 'Прогулка',
      emoji: '🚶',
      subtitle: 'walkSubtitle',
      color: Color(0xFFFFB3BA),
      targetValue: 10000,
      targetUnit: 'steps',
      unitLabel: 'шагов',
      motivation: 'walkMotivation',
      reminderTime: '08:00',
    ),
    DefaultHabit(
      id: 'read',
      name: 'Чтение',
      emoji: '📚',
      subtitle: 'readSubtitle',
      color: Color(0xFFB3E5FC),
      targetValue: 30,
      targetUnit: 'pages',
      unitLabel: 'страниц',
      motivation: 'readMotivation',
      reminderTime: '21:00',
    ),
    DefaultHabit(
      id: 'water',
      name: 'Пить воду',
      emoji: '💧',
      subtitle: 'waterSubtitle',
      color: Color(0xFFB3FFB3),
      targetValue: 2000,
      targetUnit: 'ml',
      unitLabel: 'мл',
      motivation: 'waterMotivation',
      reminderTime: '09:00',
    ),
    DefaultHabit(
      id: 'meditate',
      name: 'Медитация',
      emoji: '🧘',
      subtitle: 'meditateSubtitle',
      color: Color(0xFFE5B3FF),
      targetValue: 15,
      targetUnit: 'min',
      unitLabel: 'мин',
      motivation: 'meditateMotivation',
    ),
    DefaultHabit(
      id: 'run',
      name: 'Бег',
      emoji: '🏃',
      subtitle: 'runSubtitle',
      color: Color(0xFFFFD8B3),
      targetValue: 5,
      targetUnit: 'km',
      unitLabel: 'км',
      motivation: 'runMotivation',
    ),
    DefaultHabit(
      id: 'sleep',
      name: 'Ранний сон',
      emoji: '😴',
      subtitle: 'sleepSubtitle',
      color: Color(0xFFFFF4B3),
      targetValue: 8,
      targetUnit: 'hours',
      unitLabel: 'часов',
      motivation: 'sleepMotivation',
    ),
    DefaultHabit(
      id: 'workout',
      name: 'Тренировка',
      emoji: '💪',
      subtitle: 'workoutSubtitle',
      color: Color(0xFFFFB3E5),
      targetValue: 45,
      targetUnit: 'min',
      unitLabel: 'мин',
      motivation: 'workoutMotivation',
    ),
    DefaultHabit(
      id: 'journal',
      name: 'Дневник',
      emoji: '✍️',
      subtitle: 'journalSubtitle',
      color: Color(0xFFB3FFF4),
      targetValue: 1,
      targetUnit: 'times',
      unitLabel: 'записей',
      motivation: 'journalMotivation',
    ),
  ];

  static const List<DefaultHabit> badHabits = [
    DefaultHabit(
      id: 'smoke',
      name: 'Бросить курить',
      emoji: '🚭',
      subtitle: 'smokeSubtitle',
      color: Color(0xFFFFB3BA),
      targetValue: 0,
      targetUnit: 'times',
      unitLabel: 'сигарет',
      isGoodHabit: false,
      motivation: 'smokeMotivation',
    ),
    DefaultHabit(
      id: 'sugar',
      name: 'Меньше сахара',
      emoji: '🍰',
      subtitle: 'sugarSubtitle',
      color: Color(0xFFFFD8B3),
      targetValue: 25,
      targetUnit: 'cal',
      unitLabel: 'кал',
      isGoodHabit: false,
      motivation: 'sugarMotivation',
    ),
    DefaultHabit(
      id: 'social',
      name: 'Меньше соцсетей',
      emoji: '📱',
      subtitle: 'socialSubtitle',
      color: Color(0xFFB3E5FC),
      targetValue: 30,
      targetUnit: 'min',
      unitLabel: 'мин',
      isGoodHabit: false,
      motivation: 'socialMotivation',
    ),
    DefaultHabit(
      id: 'alcohol',
      name: 'Без алкоголя',
      emoji: '🍷',
      subtitle: 'alcoholSubtitle',
      color: Color(0xFFE5B3FF),
      targetValue: 0,
      targetUnit: 'times',
      unitLabel: 'напитков',
      isGoodHabit: false,
      motivation: 'alcoholMotivation',
    ),
    DefaultHabit(
      id: 'procrastinate',
      name: 'Перестать прокрастинировать',
      emoji: '⏰',
      subtitle: 'procrastinateSubtitle',
      color: Color(0xFFFFF4B3),
      targetValue: 1,
      targetUnit: 'times',
      unitLabel: 'задач',
      isGoodHabit: false,
      motivation: 'procrastinateMotivation',
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
