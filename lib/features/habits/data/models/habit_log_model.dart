import 'package:cloud_firestore/cloud_firestore.dart';

/// Статус выполнения привычки
enum HabitStatus {
  pending,    // В ожидании (не отмечена)
  completed,  // Выполнена успешно
  skipped,    // Пропущена
  failed,     // Провалена
}

/// Модель лога выполнения привычки
class HabitLogModel {
  final String? id;
  final String userId;
  final String habitId;
  final DateTime date; // Дата выполнения
  final bool isCompleted;
  final HabitStatus status; // Статус: pending, completed, skipped, failed
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
    this.status = HabitStatus.pending,
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
      status: _parseStatus(data['status']),
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
      'status': status.name,
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
    HabitStatus? status,
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
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      value: value ?? this.value,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Парсинг статуса из строки
  static HabitStatus _parseStatus(String? status) {
    switch (status) {
      case 'completed':
        return HabitStatus.completed;
      case 'skipped':
        return HabitStatus.skipped;
      case 'failed':
        return HabitStatus.failed;
      default:
        return HabitStatus.pending;
    }
  }

  /// Получить дату в формате YYYY-MM-DD
  String get dateKey {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Геттер для совместимости с кодом
  int get currentProgress => value ?? 0;
  
  /// Геттер для совместимости (в логе нет targetProgress, возвращаем текущий прогресс)
  int get targetProgress => value ?? 0;

  /// Создать ID для документа на основе userId, habitId и даты
  static String createId(String userId, String habitId, DateTime date) {
    final dateStr = '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    return '${userId}_${habitId}_$dateStr';
  }
}
