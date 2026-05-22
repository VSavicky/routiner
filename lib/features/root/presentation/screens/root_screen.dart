import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:routiner/core/widgets/habit_option_widget.dart';
import 'package:routiner/core/widgets/habit_bottom_sheet.dart';
import 'package:routiner/features/create_habit/presentation/screens/custom_habit_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:routiner/features/habits/data/repositories/habit_repository.dart';
import 'package:routiner/l10n/app_localizations.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key, required this.navigationShell});

  /// Контейнер для навигационного бара.
  final StatefulNavigationShell navigationShell;

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _isAddModalVisible = false;
  
  final HabitRepository _habitRepository = HabitRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
  }

  void _toggleAddModal() {
    setState(() {
      _isAddModalVisible = !_isAddModalVisible;
    });
  }

  void _closeAddModal() {
    setState(() {
      _isAddModalVisible = false;
    });
  }

  
  void _onQuitBadHabbit() {
    print('Quit Bad Habbit pressed');
    _closeAddModal();
    _showHabitBottomSheet(
      title: context.l10n.translate('quitBadHabit'),
      subtitle: context.l10n.translate('neverTooLate'),
      iconPath: 'assets/icons/ShieldDone.svg',
      isBadHabbit: true,
    );
  }

  void _onNewGoodHabbit() {
    print('New Good Habbit pressed');
    _closeAddModal();
    _showHabitBottomSheet(
      title: context.l10n.translate('newGoodHabit'),
      subtitle: context.l10n.translate('forABetterLife'),
      iconPath: 'assets/icons/ShieldFail.svg',
      isBadHabbit: false,
    );
  }

  void _onCustomHabbit() async {
    print('Custom Habbit pressed');
    _closeAddModal();
    
    // Переходим на экран создания кастомной привычки как в HabitBottomSheet
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomHabitScreen(
          isBadHabit: false, // Для кастомной привычки считаем ее хорошей
          moodEmoji: '😊',
          moodLabel: context.l10n.translate('good'),
        ),
      ),
    );
    
    // Если привычка создана, можно добавить логику обновления
    if (result != null) {
      print('Custom habit created successfully');
      // Здесь можно добавить обновление UI или уведомления
    }
  }

  void _showHabitBottomSheet({
    required String title,
    required String subtitle,
    required String iconPath,
    required bool isBadHabbit,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HabitBottomSheet(
      title: title,
      subtitle: subtitle,
        iconPath: iconPath,
        isBadHabbit: isBadHabbit,
      moodEmoji: '😊',
      moodLabel: context.l10n.translate('good'),
        onClose: () => Navigator.of(context).pop(),
        onHabitCreated: () {
          // Привычка создана - можно добавить здесь логику уведомления
          // Например, через события или глобальный ключ
          print('Habit created - refreshing...');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Основной Scaffold с навигацией (всегда виден)
        Scaffold(
          backgroundColor: AppColors.background,
          body: widget.navigationShell,
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
        ),
        
        // Модальное окно поверх всего
        if (_isAddModalVisible)
          Positioned.fill(
            child: Material(
               color: Colors.transparent,
              child: GestureDetector(
                onTap: _closeAddModal,
                child: Stack(
                  children: [
                    // Затемнение всего экрана (включая таббар)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                    
                    // Кнопка Добавить/Закрыть (поверх затемнения)
                    Positioned(
                      bottom: 16 + 20, // margin.bottom + padding.vertical
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Кнопка Добавить/Закрыть (активная)
                          _buildAddNavItem(
                            icon: _isAddModalVisible ? Icons.close : Icons.add,
                            label: context.l10n.translate('add'),
                            isActive: widget.navigationShell.currentIndex == 2,
                            onTap: _toggleAddModal,
                            size: 30.0,
                          ),
                        ],
                      ),
                    ),
                    
                    // Контейнеры внизу над кнопкой
                    Positioned(
                      bottom: 100, // Сразу над кнопкой (кнопка на 36px от низа)
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Верхний широкий контейнер для кастомной привычки
                          GestureDetector(
                            onTap: _onCustomHabbit,
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: 24),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              height: 80,
                            child: Row(
                              children: [
                                // Центрированный текст на всю ширину
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        context.l10n.translate('customHabit'),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.black100,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        context.l10n.translate('createYourOwnRoutine'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.black40,
                                          fontFamily: 'SF Pro Display',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            ),
                          ),
                          
                          SizedBox(height: 8), // Отступ между блоками
                          
                          // Два узких контейнера вверху
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                // Левый узкий контейнер
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _onQuitBadHabbit,
                                    child: Container(
                                      height: 90, // Увеличиваем с 70 до 90 для соответствия
                                      padding: EdgeInsets.all(16), // Увеличиваем паддинг для большего пространства
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          // Текст слева
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                    context.l10n.translate('quitBadHabit'),
                                                  style: TextStyle(
                                                    fontSize: 14, // Увеличиваем с 11 до 14
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.black100,
                                                  ),
                                                ),
                                                SizedBox(height: 2), // Увеличиваем отступ
                                                Text(
                                                    context.l10n.translate('neverTooLate'),
                                                  style: TextStyle(
                                                    fontSize: 11, // Увеличиваем с 9 до 11
                                                    color: AppColors.black40,
                                                    fontFamily: 'SF Pro Display',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        
                                          SizedBox(width: 6), // Уменьшил с 8 до 6
                                        
                                          // Иконка справа
                                          Container(
                                            width: 20, // Уменьшил с 24 до 20
                                            height: 20, // Уменьшил с 24 до 20
                                            child: SvgPicture.asset(
                                              'assets/icons/ShieldFail.svg',
                                              width: 16,
                                              height: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                
                                SizedBox(width: 8), // Расстояние между контейнерами
                                
                                // Правый узкий контейнер
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _onNewGoodHabbit,
                                    child: Container(
                                      height: 90, // Увеличиваем с 70 до 90 для лучшего вида
                                      padding: EdgeInsets.all(16), // Увеличиваем паддинг для большего пространства
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          // Текст слева
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                    context.l10n.translate('newGoodHabit'),
                                                  style: TextStyle(
                                                    fontSize: 14, // Увеличиваем с 11 до 14
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.black100,
                                                  ),
                                                ),
                                                SizedBox(height: 2), // Увеличиваем отступ
                                                Text(
                                                    context.l10n.translate('forABetterLife'),
                                                  style: TextStyle(
                                                    fontSize: 11, // Увеличиваем с 9 до 11
                                                    color: AppColors.black40,
                                                    fontFamily: 'SF Pro Display',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        
                                          SizedBox(width: 6), // Уменьшил с 8 до 6
                                        
                                          // Иконка справа
                                          Container(
                                            width: 20, // Уменьшил с 24 до 20
                                            height: 20, // Уменьшил с 24 до 20
                                            child: SvgPicture.asset(
                                              'assets/icons/ShieldDone.svg',
                                              width: 16,
                                              height: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                                                  ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Неактивная кнопка (затемненная)
  Widget _buildDisabledNavItem() {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      child: Icon(
        Icons.home, // Любая иконка, она будет затемнена
        size: 30,
        color: Colors.black.withOpacity(0.3), // Затемненная
      ),
    );
  }

  // Блок опции для создания привычки
  Widget _buildHabitOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.black10,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Иконка
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.purple,
                    AppColors.blue,
                  ],
                  stops: [0.0, 1.0],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            
            // Текст
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black100,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.black40,
                    ),
                  ),
                ],
              ),
            ),
            
            // Стрелка
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.black40,
              size: 16,
            ),
          ],
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
        label: context.l10n.translate('home'),
        isActive: widget.navigationShell.currentIndex == 0,
        onTap: () => _navigateToIndex(0),
      ),
      // Статистика
      _buildNavItem(
        icon: Icons.bar_chart,
        label: context.l10n.translate('analytics'),
        isActive: widget.navigationShell.currentIndex == 1,
        onTap: () => _navigateToIndex(1),
      ),
      // Добавить (увеличенная иконка с градиентом)
      _buildAddNavItem(
        icon: _isAddModalVisible ? Icons.close : Icons.add,
        label: context.l10n.translate('add'),
        isActive: widget.navigationShell.currentIndex == 2,
        onTap: _toggleAddModal,
        size: 30.0, // Обычный размер как у других кнопок
      ),
      // Библиотека
      _buildNavItem(
        icon: Icons.library_books,
        label: context.l10n.translate('library'),
        isActive: widget.navigationShell.currentIndex == 3,
        onTap: () => _navigateToIndex(3),
      ),
      // Профиль
      _buildNavItem(
        icon: Icons.person,
        label: context.l10n.translate('profile'),
        isActive: widget.navigationShell.currentIndex == 4,
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
          size: size ?? 30, // Используем переданный размер или по умолчанию 24
          color: isActive ? AppColors.blue100 : AppColors.black40,
        ),
      ),
    );
  }

  // Строит кнопку Добавить с градиентом
  Widget _buildAddNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    double? size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, // Обычный размер как у других кнопок
        height: 40, // Обычный размер как у других кнопок
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.purple,
              AppColors.blue,
            ],
            stops: [0.0, 1.0],
          ),
          borderRadius: BorderRadius.circular(20), // Полукруглая кнопка обычного размера
        ),
        child: Icon(
          icon,
          size: size ?? 30,
          color: Colors.white, // Белый плюс
        ),
      ),
    );
  }

  // Навигация на нужный индекс
  void _navigateToIndex(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}
