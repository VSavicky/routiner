import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/core/widgets/notification_icon.dart';

class Habit {
  final String id;
  final String title;
  final String subtitle;
  final int friendsCount;
  final int currentProgress;
  final int targetProgress;
  final VoidCallback? onViewPressed;
  final VoidCallback? onDonePressed;
  final VoidCallback? onFallPressed;
  final VoidCallback? onSkipPressed;
  final VoidCallback? onAddFriendPressed;
  final VoidCallback? onFriendsPressed;

  Habit({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.friendsCount,
    required this.currentProgress,
    required this.targetProgress,
    this.onViewPressed,
    this.onDonePressed,
    this.onFallPressed,
    this.onSkipPressed,
    this.onAddFriendPressed,
    this.onFriendsPressed,
  });

  bool get isCompleted => currentProgress >= targetProgress;
}

class HabitsWidget extends StatefulWidget {
  final List<Habit> habits;
  final VoidCallback? onViewAllPressed;

  const HabitsWidget({
    super.key,
    required this.habits,
    this.onViewAllPressed,
  });

  @override
  State<HabitsWidget> createState() => _HabitsWidgetState();
}

class _HabitsWidgetState extends State<HabitsWidget> {
  // Состояния видимости боковых панелей для каждой привычки
  final Map<String, bool> _leftPanelVisible = {};
  final Map<String, bool> _rightPanelVisible = {};

  void _onHorizontalDragEnd(String habitId, DragEndDetails details) {
    setState(() {
      if (details.primaryVelocity! > 0) {
        // Свайп вправо
        if (_rightPanelVisible[habitId] == true) {
          // Если видна правая панель - возвращаем основной контейнер
          _leftPanelVisible[habitId] = false;
          _rightPanelVisible[habitId] = false;
        } else {
          // Иначе показываем левую боковую панель
          _leftPanelVisible[habitId] = true;
          _rightPanelVisible[habitId] = false;
        }
      } else if (details.primaryVelocity! < 0) {
        // Свайп влево
        if (_leftPanelVisible[habitId] == true) {
          // Если видна левая панель - возвращаем основной контейнер
          _leftPanelVisible[habitId] = false;
          _rightPanelVisible[habitId] = false;
        } else {
          // Иначе показываем правую боковую панель
          _leftPanelVisible[habitId] = false;
          _rightPanelVisible[habitId] = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок привычек
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Habits',
              style: AppFonts.bodyTitleMedium.copyWith(
                color: AppColors.black100,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            GestureDetector(
              onTap: widget.onViewAllPressed,
              child: Text(
                'VIEW ALL',
                style: AppFonts.bodyTitleMedium.copyWith(
                  color: AppColors.blue100,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 5),
        // Список контейнеров привычек
        ...widget.habits.asMap().entries.map((entry) {
          final index = entry.key;
          final habit = entry.value;
          
          return Padding(
            padding: EdgeInsets.only(bottom: index < widget.habits.length - 1 ? 16.0 : 0.0),
            child: _HabitContainer(
              habit: habit,
              isLeftPanelVisible: _leftPanelVisible[habit.id] ?? false,
              isRightPanelVisible: _rightPanelVisible[habit.id] ?? false,
              onHorizontalDragEnd: (details) => _onHorizontalDragEnd(habit.id, details),
            ),
          );
        }).toList(),
      ],
    );
  }
}

class _HabitContainer extends StatelessWidget {
  final Habit habit;
  final bool isLeftPanelVisible;
  final bool isRightPanelVisible;
  final Function(DragEndDetails) onHorizontalDragEnd;

  const _HabitContainer({
    required this.habit,
    required this.isLeftPanelVisible,
    required this.isRightPanelVisible,
    required this.onHorizontalDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80, // Фиксированная высота для Stack
      child: ClipRect( // Обрезаем контент чтобы не было overflow
        child: GestureDetector(
          onHorizontalDragEnd: onHorizontalDragEnd,
          onTap: () {
            // TODO: Добавить обработку нажатия на контейнер
            print('Habit container pressed: ${habit.title}');
          },
          child: Stack(
            children: [
              // Основной контейнер привычек (сдвигается при свайпе)
              AnimatedPositioned(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: isLeftPanelVisible ? 125.0 : (isRightPanelVisible ? -125.0 : 0.0), // Сдвиг влево или вправо
                top: 0,
                right: isLeftPanelVisible ? -125.0 : (isRightPanelVisible ? 125.0 : 0.0), // Компенсируем сдвиг
                bottom: 0,
                child: Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.black10,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Левая часть - прогресс-бар и текст
                        Expanded( // Используем Expanded чтобы избежать overflow
                          child: Row(
                            children: [
                              // Круглый прогресс-бар со смайликом
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: habit.isCompleted ? AppColors.green40 : AppColors.blue10,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: habit.isCompleted 
                                          ? Icon(
                                              Icons.check,
                                              color: AppColors.green40,
                                              size: 16,
                                            )
                                          : Text(
                                              '💧',
                                              style: TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              // Колонка с текстом
                              Expanded( // Используем Expanded для текста
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      habit.title,
                                      style: AppFonts.bodyTitleMedium.copyWith(
                                        color: AppColors.black100,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis, // Обрезаем длинный текст
                                      maxLines: 1,
                                    ),
                                    SizedBox(height: 1),
                                    Text(
                                      habit.isCompleted ? 'Completed!' : habit.subtitle,
                                      style: AppFonts.bodyAlternative.copyWith(
                                        color: habit.isCompleted ? AppColors.green40 : AppColors.black40,
                                        fontSize: 11,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis, // Обрезаем длинный текст
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Правая часть - круги и иконка добавления
                        Row(
                          mainAxisSize: MainAxisSize.min, // Минимальный размер
                          children: [
                            // Круги с друзьями
                            GestureDetector(
                              onTap: habit.onFriendsPressed ?? () {
                                print('Friends pressed: ${habit.title}');
                              },
                              child: Container(
                                width: 100,
                                height: 30,
                                child: Stack(
                                  alignment: Alignment.centerRight,
                                  children: _buildFriendCircles(habit.friendsCount),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            // Иконка добавления
                            NotificationIcon(
                              icon: habit.isCompleted ? Icons.check : Icons.add,
                              hasNotification: false,
                              onTap: habit.onAddFriendPressed ?? () {
                                print('Add friend pressed: ${habit.title}');
                              },
                              size: 20,
                              iconColor: habit.isCompleted ? AppColors.green40 : AppColors.black100,
                              showBorder: true,
                              borderColor: AppColors.black10,
                              borderWidth: 2.0,
                              borderRadius: 16.0,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Левая боковая панель (выдвигается при свайпе вправо)
              AnimatedPositioned(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: isLeftPanelVisible ? 0.0 : -120.0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 120,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.black10,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Левый столбик - икона глаза и View
                        GestureDetector(
                          onTap: habit.onViewPressed ?? () {
                            print('View pressed: ${habit.title}');
                            // Если привычка выполнена, добавляем функционал как при 100%
                            if (habit.isCompleted) {
                              print('Habit already completed - showing completion effects');
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.visibility,
                                color: AppColors.black40,
                                size: 20,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'View',
                                style: AppFonts.bodyAlternative.copyWith(
                                  color: AppColors.black40,
                                  fontSize: 11,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Вертикальный разделитель
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.black10,
                        ),
                        // Правый столбик - галочка и Done
                        GestureDetector(
                          onTap: habit.onDonePressed ?? () {
                            print('Done pressed: ${habit.title}');
                            // Если привычка выполнена, добавляем функционал как при 100%
                            if (habit.isCompleted) {
                              print('Habit already completed - showing completion effects');
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppColors.green40,
                                size: 20,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Done',
                                style: AppFonts.bodyAlternative.copyWith(
                                  color: AppColors.black40,
                                  fontSize: 11,
                                  fontWeight: FontWeight.normal,
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
              // Правая боковая панель (выдвигается при свайпе влево)
              AnimatedPositioned(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                right: isRightPanelVisible ? 0.0 : -120.0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 120,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.black10,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Левый столбик - крестик и Fall
                        GestureDetector(
                          onTap: habit.onFallPressed ?? () {
                            print('Fall pressed: ${habit.title}');
                            // TODO: Добавить логику для проваленной привычки
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.close,
                                color: AppColors.red,
                                size: 20,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Fall',
                                style: AppFonts.bodyAlternative.copyWith(
                                  color: AppColors.black40,
                                  fontSize: 11,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Вертикальный разделитель
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.black10,
                        ),
                        // Правый столбик - стрелка вправо и Skip
                        GestureDetector(
                          onTap: habit.onSkipPressed ?? () {
                            print('Skip pressed: ${habit.title}');
                            // TODO: Добавить логику для пропущенной привычки
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_forward,
                                color: AppColors.black100,
                                size: 20,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Skip',
                                style: AppFonts.bodyAlternative.copyWith(
                                  color: AppColors.black40,
                                  fontSize: 11,
                                  fontWeight: FontWeight.normal,
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
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFriendCircles(int friendsCount) {
    List<Widget> circles = [];
    
    if (friendsCount <= 3) {
      // Показываем точное количество друзей
      for (int i = 0; i < friendsCount; i++) {
        circles.add(_buildFriendCircle(i, friendsCount));
      }
    } else {
      // Больше 3 друзей - показываем 2 круга и +N
      circles.add(_buildFriendCircle(0, friendsCount));
      circles.add(_buildFriendCircle(1, friendsCount));
      circles.add(_buildPlusCircle(friendsCount - 2));
    }
    
    return circles;
  }

  Widget _buildFriendCircle(int index, int totalCount) {
    // Цвета для кругов друзей
    List<Color> colors = [AppColors.blue10, AppColors.purple.withOpacity(0.2)];
    List<Color> innerColors = [AppColors.blue40, AppColors.purple];
    
    Color color = colors[index % colors.length];
    Color innerColor = innerColors[index % innerColors.length];
    
    // Позиционирование от правого края
    double rightOffset = index * 12.0; // 12px между кругами (круги 30x30)
    
    return Positioned(
      right: rightOffset,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 1,
          ),
        ),
        child: Center(
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: innerColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlusCircle(int additionalCount) {
    return Positioned(
      right: 24.0, // Третий круг (30px)
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.orange10,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            '+$additionalCount',
            style: AppFonts.bodyAlternative.copyWith(
              color: AppColors.black100,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
