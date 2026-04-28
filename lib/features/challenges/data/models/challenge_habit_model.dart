import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель привычки челленджа
/// Хранит связь между челленджем и привычкой пользователя
class ChallengeHabitModel {
  final String? id;
  final String userId;
  final String challengeId;
  final String habitId; // ID привычки в коллекции habits
  final String name;
  final String emoji;
  final int targetValue;
  final String targetUnit;
  final int incrementStep;
  final String habitType; // 'build' или 'quit'
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isCompleted;

  ChallengeHabitModel({
    this.id,
    required this.userId,
    required this.challengeId,
    required this.habitId,
    required this.name,
    required this.emoji,
    this.targetValue = 1,
    this.targetUnit = 'times',
    this.incrementStep = 1,
    this.habitType = 'build',
    DateTime? createdAt,
    this.completedAt,
    this.isCompleted = false,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Конвертация из Firestore документа
  factory ChallengeHabitModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeHabitModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      challengeId: data['challengeId'] ?? '',
      habitId: data['habitId'] ?? '',
      name: data['name'] ?? '',
      emoji: data['emoji'] ?? '🎯',
      targetValue: data['targetValue'] ?? 1,
      targetUnit: data['targetUnit'] ?? 'times',
      incrementStep: data['incrementStep'] ?? 1,
      habitType: data['habitType'] ?? 'build',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  /// Конвертация в Firestore формат
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'challengeId': challengeId,
      'habitId': habitId,
      'name': name,
      'emoji': emoji,
      'targetValue': targetValue,
      'targetUnit': targetUnit,
      'incrementStep': incrementStep,
      'habitType': habitType,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'isCompleted': isCompleted,
    };
  }

  /// Копия с изменениями
  ChallengeHabitModel copyWith({
    String? id,
    String? userId,
    String? challengeId,
    String? habitId,
    String? name,
    String? emoji,
    int? targetValue,
    String? targetUnit,
    int? incrementStep,
    String? habitType,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isCompleted,
  }) {
    return ChallengeHabitModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      challengeId: challengeId ?? this.challengeId,
      habitId: habitId ?? this.habitId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      targetValue: targetValue ?? this.targetValue,
      targetUnit: targetUnit ?? this.targetUnit,
      incrementStep: incrementStep ?? this.incrementStep,
      habitType: habitType ?? this.habitType,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
