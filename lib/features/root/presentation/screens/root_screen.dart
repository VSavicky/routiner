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
      body: navigationShell,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16), // Отступ 16px снизу
          width: double.infinity, // Ограничиваем ширину контейнера
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(64)), // Все углы скруглены на 64px
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(64)), // Все углы скруглены на 64px
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), // Отступы 20px по бокам
              width: double.infinity, // Ограничиваем ширину внутреннего контейнера
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _buildBottomNavBarItems(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Возвращает список виджетов для нижней навигации
  List<Widget> _buildBottomNavBarItems() {
    return [
      // Главная
      _buildNavItem(
        icon: Icons.home,
        label: 'Главная',
        isActive: navigationShell.currentIndex == 0,
        onTap: () => _navigateToIndex(0),
      ),
      // Статистика
      _buildNavItem(
        icon: Icons.bar_chart,
        label: 'Статистика',
        isActive: navigationShell.currentIndex == 1,
        onTap: () => _navigateToIndex(1),
      ),
      // Добавить (увеличенная иконка)
      _buildNavItem(
        icon: Icons.add_circle,
        label: 'Добавить',
        isActive: navigationShell.currentIndex == 2,
        onTap: () => _navigateToIndex(2),
        size: 48.0, // Увеличена в 2 раза (было 24)
      ),
      // Библиотека
      _buildNavItem(
        icon: Icons.library_books,
        label: 'Библиотека',
        isActive: navigationShell.currentIndex == 3,
        onTap: () => _navigateToIndex(3),
      ),
      // Профиль
      _buildNavItem(
        icon: Icons.person,
        label: 'Профиль',
        isActive: navigationShell.currentIndex == 4,
        onTap: () => _navigateToIndex(4),
      ),
    ];
  }

  // Строит один элемент навигации
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    double? size, // Добавляем опциональный параметр размера
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: size ?? 24.0, // Используем переданный размер или по умолчанию 24
          color: isActive ? AppColors.blue100 : AppColors.black40,
        ),
      ),
    );
  }

  // Навигация на нужный индекс
  void _navigateToIndex(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
