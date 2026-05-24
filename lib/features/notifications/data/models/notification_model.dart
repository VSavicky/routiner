import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель уведомления
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // achievement, reminder, etc.
  final String? icon; // Эмодзи или иконка
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.icon,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'achievement',
      icon: data['icon'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'icon': icon,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }
}
