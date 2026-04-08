import 'package:flutter/material.dart';
import 'package:go_router/src/route.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:routiner/core/widgets/habit_option_widget.dart';
import 'package:routiner/core/widgets/habit_bottom_sheet.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key, required this.navigationShell});

  /// Контейнер для навигационного бара.
  final StatefulNavigationShell navigationShell;

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _isAddModalVisible = false;
  int _selectedMoodIndex = 0; // Выбранная иконка настроения

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

  void _selectMood(int index) {
    setState(() {
      _selectedMoodIndex = index;
    });
  }

  void _onQuitBadHabbit() {
    print('Quit Bad Habbit pressed');
    _closeAddModal();
    _showHabitBottomSheet(
      title: 'Quit Bad Habbit',
      subtitle: 'Never too late...',
      iconPath: 'assets/icons/ShieldDone.svg',
      isBadHabbit: true,
    );
  }

  void _onNewGoodHabbit() {
    print('New Good Habbit pressed');
    _closeAddModal();
    _showHabitBottomSheet(
      title: 'New Good Habbit',
      subtitle: 'For a better life',
      iconPath: 'assets/icons/ShieldFail.svg',
      isBadHabbit: false,
    );
  }

  void _showHabitBottomSheet({
    required String title,
    required String subtitle,
    required String iconPath,
    required bool isBadHabbit,
  }) {
    // Смайлики и лейблы для настроений
    List<String> moodEmojis = ['😡', '☹', '😐', '🙂', '😍 '];
    List<String> moodLabels = ['Angry', 'Sad', 'Neutral', 'Happy', 'Love'];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HabitBottomSheet(
        title: title,
        subtitle: subtitle,
        iconPath: iconPath,
        isBadHabbit: isBadHabbit,
        moodEmoji: moodEmojis[_selectedMoodIndex],
        moodLabel: moodLabels[_selectedMoodIndex],
        onClose: () => Navigator.of(context).pop(),
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
                            label: 'Добавить',
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
                                      height: 70, // Увеличил с 50 до 70 чтобы все помещалось по центру
                                      padding: EdgeInsets.all(10), // Уменьшил с 16 до 10
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
                                                  'Quit Bad Habbit',
                                                  style: TextStyle(
                                                    fontSize: 11, // Уменьшил с 12 до 11
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.black100,
                                                    fontFamily: 'SF Pro Display', // Добавляю fontFamily
                                                  ),
                                                ),
                                                SizedBox(height: 1), // Уменьшил с 2 до 1
                                                Text(
                                                  'Never too late...',
                                                  style: TextStyle(
                                                    fontSize: 9, // Уменьшил с 10 до 9
                                                    color: AppColors.black40,
                                                    fontFamily: 'SF Pro Display', // Добавляю fontFamily
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
                                      height: 70, // Увеличил с 50 до 70 чтобы все помещалось по центру
                                      padding: EdgeInsets.all(10), // Уменьшил с 16 до 10
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
                                                  'New Good Habbit',
                                                  style: TextStyle(
                                                    fontSize: 11, // Уменьшил с 12 до 11
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.black100,
                                                  ),
                                                ),
                                                SizedBox(height: 1), // Уменьшил с 2 до 1
                                                Text(
                                                  'For a better life',
                                                  style: TextStyle(
                                                    fontSize: 9, // Уменьшил с 10 до 9
                                                    color: AppColors.black40,
                                                    fontFamily: 'SF Pro Display', // Добавляю fontFamily
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
                          
                          SizedBox(height: 8), // Отступ над широким контейнером
                          
                          // Широкий контейнер внизу
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 24),
                            padding: EdgeInsets.all(12), // Уменьшил внутренний паддинг с 16 до 12
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            height: 70,
                            child: Row(
                              children: [
                                // Текст слева
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Add Mood',
                                        style: AppFonts.bodyTitleMedium.copyWith(
                                          color: AppColors.black100,
                                          fontSize: 14, // Уменьшил с 16 до 14
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 1), // Уменьшил с 2 до 1
                                      Text(
                                        'how are you feeling?',
                                        style: AppFonts.bodyAlternative.copyWith(
                                          color: AppColors.black40,
                                          fontSize: 10, // Уменьшил с 12 до 10
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                SizedBox(width: 12), // Уменьшил с 16 до 12
                                
                                // 5 иконок настроения справа
                                Row(
                                  children: [
                                    for (var index = 0; index < 5; index++)
                                      Padding(
                                        padding: EdgeInsets.only(left: index > 0 ? 6.0 : 0.0), // Уменьшил с 8 до 6
                                        child: _buildMoodIcon(index),
                                      ),
                                  ],
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

  // Иконка настроения
  Widget _buildMoodIcon(int index) {
    // Смайлики для настроений в правильном порядке
    List<String> moodEmojis = ['😡', '☹', '😐', '🙂', '😍 '];
    
    bool isSelected = _selectedMoodIndex == index;
    
    return GestureDetector(
      onTap: () => _selectMood(index),
      child: Container(
        width: 32, // Уменьшил с 36 до 32
        height: 32, // Уменьшил с 36 до 32
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue10 : Colors.transparent,
          borderRadius: BorderRadius.circular(12), // Уменьшил с 18 до 16
          border: Border.all(
            color: isSelected ? AppColors.blue100 : AppColors.black10,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            moodEmojis[index],
            style: TextStyle(
              fontSize: 16, // Уменьшил с 18 до 16
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
        isActive: widget.navigationShell.currentIndex == 0,
        onTap: () => _navigateToIndex(0),
      ),
      // Статистика
      _buildNavItem(
        icon: Icons.bar_chart,
        label: 'Статистика',
        isActive: widget.navigationShell.currentIndex == 1,
        onTap: () => _navigateToIndex(1),
      ),
      // Добавить (увеличенная иконка с градиентом)
      _buildAddNavItem(
        icon: _isAddModalVisible ? Icons.close : Icons.add,
        label: 'Добавить',
        isActive: widget.navigationShell.currentIndex == 2,
        onTap: _toggleAddModal,
        size: 30.0, // Обычный размер как у других кнопок
      ),
      // Библиотека
      _buildNavItem(
        icon: Icons.library_books,
        label: 'Библиотека',
        isActive: widget.navigationShell.currentIndex == 3,
        onTap: () => _navigateToIndex(3),
      ),
      // Профиль
      _buildNavItem(
        icon: Icons.person,
        label: 'Профиль',
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
