import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель для хранения настроения пользователя
class MoodModel {
  final String? id;
  final String userId;
  final String emoji;
  final String label;
  final DateTime date;
  final DateTime createdAt;

  MoodModel({
    this.id,
    required this.userId,
    required this.emoji,
    required this.label,
    required this.date,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Создание из Firestore документа
  factory MoodModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MoodModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      emoji: data['emoji'] ?? '😐',
      label: data['label'] ?? 'Neutral',
      date: (data['date'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Конвертация в Map для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'emoji': emoji,
      'label': label,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Копирование с изменениями
  MoodModel copyWith({
    String? id,
    String? userId,
    String? emoji,
    String? label,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return MoodModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      emoji: emoji ?? this.emoji,
      label: label ?? this.label,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
