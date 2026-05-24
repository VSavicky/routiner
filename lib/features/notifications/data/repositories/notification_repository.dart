import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routiner/features/notifications/data/models/notification_model.dart';

/// Репозиторий для работы с уведомлениями
class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить уведомления пользователя
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
      // Сортируем на клиенте по дате (новые сверху)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  /// Получить непрочитанные уведомления
  Future<List<NotificationModel>> getUnreadNotifications(String userId) async {
    // Получаем все уведомления пользователя и фильтруем на клиенте
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .limit(200)
        .get();

    final notifications = snapshot.docs
        .map((doc) => NotificationModel.fromFirestore(doc))
        .where((notification) => !notification.isRead)
        .toList();
    
    // Сортируем на клиенте
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notifications;
  }

  /// Создать уведомление
  Future<void> createNotification(NotificationModel notification) async {
    await _firestore.collection('notifications').add(notification.toMap());
  }

  /// Отметить уведомление как прочитанное
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  /// Отметить все уведомления как прочитанные
  Future<void> markAllAsRead(String userId) async {
    final unread = await getUnreadNotifications(userId);
    final batch = _firestore.batch();

    for (final notification in unread) {
      final docRef = _firestore
          .collection('notifications')
          .doc(notification.id);
      batch.update(docRef, {'isRead': true});
    }

    await batch.commit();
  }

  /// Получить количество непрочитанных уведомлений
  Future<int> getUnreadCount(String userId) async {
    // Получаем последние уведомления и считаем непрочитанные на клиенте
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .limit(300)
        .get();

    return snapshot.docs
        .map((doc) => NotificationModel.fromFirestore(doc))
        .where((notification) => !notification.isRead)
        .length;
  }
}
