import 'package:cloud_firestore/cloud_firestore.dart';

class AchievementModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String icon;
  final AchievementType type;
  final DateTime earnedAt;
  final Map<String, dynamic>? metadata; // Дополнительные данные для конкретного типа

  const AchievementModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.earnedAt,
    this.metadata,
  });

  factory AchievementModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return AchievementModel(
      id: documentId,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '🏆',
      type: _parseAchievementType(data['type']),
      earnedAt: (data['earnedAt'] as Timestamp).toDate(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'icon': icon,
      'type': type.toString(),
      'earnedAt': Timestamp.fromDate(earnedAt),
      'metadata': metadata,
    };
  }

  static AchievementType _parseAchievementType(String? typeString) {
    switch (typeString) {
      case 'AchievementType.challenge':
        return AchievementType.challenge;
      case 'AchievementType.club':
        return AchievementType.club;
      case 'AchievementType.points':
        return AchievementType.points;
      case 'AchievementType.streak':
        return AchievementType.streak;
      default:
        return AchievementType.points;
    }
  }
}

enum AchievementType {
  challenge, // За выполнение челленджей
  club,      // За вступление в клубы
  points,     // За накопление очков
  streak,     // За серии выполнения привычек
}
