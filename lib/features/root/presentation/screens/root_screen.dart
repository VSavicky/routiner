import 'package:flutter/material.dart';
import 'package:go_router/src/route.dart';
import 'package:routiner/core/constants/app_colors.dart';

class RootScreen extends StatelessWidget {
  const RootScreen({super.key, required this.navigationShell});

  /// Контейнер для навигационного бара.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: navigationShell,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.blue100,
        unselectedItemColor: AppColors.black40,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: _buildBottomNavBarItems,
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }

  // Возвращает лист элементов для нижнего навигационного бара.
  List<BottomNavigationBarItem> get _buildBottomNavBarItems => [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Главная',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Статистика',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.add_circle),
          label: 'Добавить',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.library_books),
          label: 'Библиотека',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Профиль',
        ),
      ];
}
