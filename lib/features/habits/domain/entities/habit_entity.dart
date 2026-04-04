class HabitEntity {
  final String id;
  final String userId;
  final String name;
  final String emoji;
  final List<HabitDayEntity> days;

  HabitEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.emoji,
    required this.days,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'emoji': emoji,
      'days': days.map((day) => day.toMap()).toList(),
    };
  }

  factory HabitEntity.fromMap(Map<String, dynamic> map) {
    final daysList = (map['days'] as List<dynamic>)
        .map((dayMap) => HabitDayEntity.fromMap(dayMap as Map<String, dynamic>))
        .toList();

    return HabitEntity(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      emoji: map['emoji'] ?? '',
      days: daysList,
    );
  }
}

class HabitDayEntity {
  final String date;
  final bool isCompleted;
  final int streak; // Количество дней подряд

  HabitDayEntity({
    required this.date,
    required this.isCompleted,
    required this.streak,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'isCompleted': isCompleted,
      'streak': streak,
    };
  }

  factory HabitDayEntity.fromMap(Map<String, dynamic> map) {
    return HabitDayEntity(
      date: map['date'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      streak: map['streak'] ?? 0,
    );
  }
}
