import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/features/notifications/data/models/notification_model.dart';
import 'package:routiner/features/notifications/data/repositories/notification_repository.dart';
import 'package:routiner/l10n/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationRepository _repository = NotificationRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _repository.getUserNotifications(user.uid).listen((notifications) {
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;
    
    await _repository.markAsRead(notification.id);
  }

  Future<void> _markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    await _repository.markAllAsRead(user.uid);
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${_getDaysWord(difference.inDays)} назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${_getHoursWord(difference.inHours)} назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${_getMinutesWord(difference.inMinutes)} назад';
    } else {
      return 'Только что';
    }
  }

  String _getDaysWord(int days) {
    if (days % 10 == 1 && days % 100 != 11) return 'день';
    if (days % 10 >= 2 && days % 10 <= 4 && (days % 100 < 10 || days % 100 >= 20)) return 'дня';
    return 'дней';
  }

  String _getHoursWord(int hours) {
    if (hours % 10 == 1 && hours % 100 != 11) return 'час';
    if (hours % 10 >= 2 && hours % 10 <= 4 && (hours % 100 < 10 || hours % 100 >= 20)) return 'часа';
    return 'часов';
  }

  String _getMinutesWord(int minutes) {
    if (minutes % 10 == 1 && minutes % 100 != 11) return 'минута';
    if (minutes % 10 >= 2 && minutes % 10 <= 4 && (minutes % 100 < 10 || minutes % 100 >= 20)) return 'минуты';
    return 'минут';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.black100, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n!.translate('notificationsScreenTitle'),
          style: AppFonts.bodyTitleMedium.copyWith(
            color: AppColors.black100,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                l10n!.translate('markAllRead'),
                style: AppFonts.bodyAlternative.copyWith(
                  color: AppColors.blue100,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState(context)
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return _buildNotificationItem(context, notification);
                  },
                ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, NotificationModel notification) {
    final l10n = AppLocalizations.of(context);
    
    return GestureDetector(
      onTap: () => _markAsRead(notification),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : AppColors.blue10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead ? AppColors.black10 : AppColors.blue.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Иконка уведомления
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.orange10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  notification.icon ?? '🔔',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
              // Контент
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _translateNotification(l10n!, notification.title),
                      style: AppFonts.bodyTitleMedium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black100,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _translateNotification(l10n, notification.message),
                      style: AppFonts.bodyAlternative.copyWith(
                        fontSize: 13,
                        color: AppColors.black40,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTimeAgo(notification.createdAt),
                    style: AppFonts.bodyAlternative.copyWith(
                      fontSize: 11,
                      color: AppColors.black20,
                    ),
                  ),
                ],
              ),
            ),
            // Индикатор непрочитанного
            if (!notification.isRead)
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.blue100,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _translateNotification(AppLocalizations l10n, String key) {
    // Проверяем если это ключ перевода
    if (key.startsWith('notification')) {
      try {
        return l10n.translate(key);
      } catch (e) {
        return key;
      }
    }
    return key;
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.black10,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none,
              size: 40,
              color: AppColors.black20,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n!.translate('notificationsEmptyTitle'),
            style: AppFonts.bodyTitleMedium.copyWith(
              color: AppColors.black100,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n!.translate('notificationsEmptySubtitle'),
            textAlign: TextAlign.center,
            style: AppFonts.bodyAlternative.copyWith(
              color: AppColors.black40,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
