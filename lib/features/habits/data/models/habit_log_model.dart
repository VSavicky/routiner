import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель лога выполнения привычки
class HabitLogModel {
  final String? id;
  final String userId;
  final String habitId;
  final DateTime date; // Дата выполнения
  final bool isCompleted;
  final DateTime? completedAt; // Когда именно выполнено
  final int? value; // Фактическое значение (если есть цель)
  final String? note; // Комментарий
  final DateTime createdAt;

  HabitLogModel({
    this.id,
    required this.userId,
    required this.habitId,
    required this.date,
    this.isCompleted = false,
    this.completedAt,
    this.value,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Конвертация из Firestore документа
  factory HabitLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HabitLogModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      habitId: data['habitId'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isCompleted: data['isCompleted'] ?? false,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      value: data['value'],
      note: data['note'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Конвертация в Firestore формат
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'habitId': habitId,
      'date': Timestamp.fromDate(date),
      'isCompleted': isCompleted,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'value': value,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Копия с изменениями
  HabitLogModel copyWith({
    String? id,
    String? userId,
    String? habitId,
    DateTime? date,
    bool? isCompleted,
    DateTime? completedAt,
    int? value,
    String? note,
    DateTime? createdAt,
  }) {
    return HabitLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      value: value ?? this.value,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Получить дату в формате YYYY-MM-DD
  String get dateKey {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Создать ID для документа на основе userId, habitId и даты
  static String createId(String userId, String habitId, DateTime date) {
    final dateStr = '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    return '${userId}_${habitId}_$dateStr';
  }
}
