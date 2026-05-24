import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/core/widgets/notification_icon.dart';
import 'package:routiner/core/widgets/toggle_button.dart';
import 'package:routiner/features/notifications/data/repositories/notification_repository.dart';
import 'package:routiner/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:routiner/l10n/app_localizations.dart';

class Header extends StatefulWidget {
  final List<String> toggleOptions;
  final int selectedToggleIndex;
  final Function(int) onToggleChanged;
  final int? notificationCount;
  final String? userName;
  final String? greeting;
  final String? subtitle;
  final bool showNotifications;
  final bool showCalendar;
  final VoidCallback? onCalendarTap;

  const Header({
    Key? key,
    this.toggleOptions = const ['Today', 'Clubs'],
    this.selectedToggleIndex = 0,
    required this.onToggleChanged,
    this.notificationCount,
    this.userName,
    this.greeting,
    this.subtitle,
    this.showNotifications = true,
    this.showCalendar = true,
    this.onCalendarTap,
  }) : super(key: key);

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  final NotificationRepository _notificationRepository = NotificationRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  void _loadUnreadCount() {
    final user = _auth.currentUser;
    if (user == null) return;

    _notificationRepository.getUnreadCount(user.uid).then((count) {
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    });
  }

  void _showNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    ).then((_) {
      // Обновляем счетчик после возврата
      _loadUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 240,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Левая колонка: календарь и приветствие
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showCalendar)
                    NotificationIcon(
                      icon: Icons.calendar_month,
                      hasNotification: false,
                      onTap: () {
                        widget.onCalendarTap?.call();
                      },
                      size: 30,
                      iconColor: AppColors.black40,
                    ),
                  if (widget.showCalendar) SizedBox(height: 12),
                  // Приветствие пользователя
                  Text(
                    widget.greeting ?? (widget.userName != null 
                        ? context.l10n.translate('hiWithName').replaceAll('{name}', widget.userName!)
                        : context.l10n.translate('hi')),
                    style: AppFonts.bodyTitleMedium.copyWith(
                      color: AppColors.black100,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  // Подзаголовок
                  Text(
                    widget.subtitle ?? 'Let\'s make habbits toghether!',
                    style: AppFonts.body.copyWith(
                      color: AppColors.black40,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              // Правая колонка: уведомления и смайлик
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.showNotifications)
                    NotificationIcon(
                      icon: Icons.notifications,
                      hasNotification: _unreadCount > 0,
                      onTap: _showNotifications,
                      size: 30,
                      iconColor: AppColors.black40,
                    ),
                  if (widget.showNotifications) SizedBox(height: 12),
                  // Круг со смайликом
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.blue10,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('😇', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          // Тумблер выбора
          ToggleButton(
            options: widget.toggleOptions,
            selectedIndex: widget.selectedToggleIndex,
            notificationCount: widget.notificationCount,
            onToggle: widget.onToggleChanged,
          ),
        ],
      ),
    );
  }
}
