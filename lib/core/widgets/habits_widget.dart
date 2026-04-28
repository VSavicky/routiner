import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/features/habits/data/models/habit_log_model.dart';

class Habit {
  final String id;
  final String title;
  final String subtitle;
  final int friendsCount;
  final int currentProgress;
  final int targetProgress;
  final String emoji; // Иконка привычки
  final Color? color; // Цвет привычки
  final int streak; // Текущий streak
  final String habitType; // 'build' или 'quit'
  final HabitStatus status; // Текущий статус
  final int incrementStep; // Шаг инкремента (+1, +100, +15)
  final bool isChallenge; // Является ли привычка из челленджа
  final VoidCallback? onViewPressed;
  final VoidCallback? onDonePressed;
  final VoidCallback? onFallPressed;
  final VoidCallback? onSkipPressed;
  final VoidCallback? onAddFriendPressed;
  final VoidCallback? onFriendsPressed;
  final VoidCallback? onEditPressed; // Редактировать
  final VoidCallback? onArchivePressed; // В архив
  final void Function(int)? onAddPressed; // Добавить шаг (+) с умным шагом

  Habit({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.friendsCount,
    required this.currentProgress,
    required this.targetProgress,
    this.emoji = '💧',
    this.color,
    this.streak = 0,
    this.habitType = 'build',
    this.status = HabitStatus.pending,
    this.incrementStep = 1,
    this.isChallenge = false,
    this.onViewPressed,
    this.onDonePressed,
    this.onFallPressed,
    this.onSkipPressed,
    this.onAddFriendPressed,
    this.onFriendsPressed,
    this.onEditPressed,
    this.onArchivePressed,
    this.onAddPressed,
  });

  bool get isCompleted => currentProgress >= targetProgress;
  bool get isSkipped => status == HabitStatus.skipped;
  bool get isFailed => status == HabitStatus.failed;
  bool get isPending => status == HabitStatus.pending;
  
  /// Процент выполнения (0.0 - 1.0)
  double get progressPercent {
    if (targetProgress <= 0) return 0.0;
    final percent = currentProgress / targetProgress;
    return percent.clamp(0.0, 1.0);
  }
  
  /// Цвет прогресса
  Color get progressColor {
    if (isCompleted) return AppColors.green40;
    if (isFailed) return AppColors.red;
    if (isSkipped) return AppColors.black40;
    return color ?? AppColors.blue100;
  }
  
  /// Цвет текста
  Color getTextColor(bool isDarkBackground) {
    if (isCompleted) return AppColors.green40;
    if (isFailed) return AppColors.red;
    if (isSkipped) return isDarkBackground ? Colors.white.withOpacity(0.5) : AppColors.black40;
    return isDarkBackground ? Colors.white : AppColors.black100;
  }
  
  /// Фоновый цвет контейнера
  Color getBackgroundColor(bool isDarkBackground) {
    if (isSkipped) return isDarkBackground ? Colors.white.withOpacity(0.1) : AppColors.black10;
    return isDarkBackground ? Colors.white.withOpacity(0.15) : Colors.white;
  }
  
  /// Текст статуса
  String get statusText {
    if (isCompleted) return 'Completed!';
    if (isFailed) return 'Failed';
    if (isSkipped) return 'Skipped';
    return subtitle;
  }
  
  /// Умный шаг инкремента на основе цели
  int get smartIncrementStep {
    if (targetProgress <= 10) return 1;
    if (targetProgress <= 20) return 5;
    if (targetProgress <= 50) return 10;
    if (targetProgress <= 100) return 20;
    if (targetProgress <= 500) return 50;
    if (targetProgress <= 1000) return 100;
    return (targetProgress / 10).ceil(); // Делим на 10 частей
  }
}

class HabitsWidget extends StatefulWidget {
  final List<Habit> habits;
  final VoidCallback? onViewAllPressed;
  final bool isDarkBackground; // true = белые цвета для темного фона

  const HabitsWidget({
    super.key,
    required this.habits,
    this.onViewAllPressed,
    this.isDarkBackground = false,
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

  /// Сброс панелей в исходное состояние (вызывается после действий Done, Fall, Skip)
  void _resetPanels(String habitId) {
    setState(() {
      _leftPanelVisible[habitId] = false;
      _rightPanelVisible[habitId] = false;
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
                color: widget.isDarkBackground ? Colors.white : AppColors.black100,
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
              isDarkBackground: widget.isDarkBackground,
              onHorizontalDragEnd: (details) => _onHorizontalDragEnd(habit.id, details),
              onResetPanels: () => _resetPanels(habit.id),
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
  final VoidCallback onResetPanels; // Сброс позиции после действий
  final bool isDarkBackground;

  const _HabitContainer({
    required this.habit,
    required this.isLeftPanelVisible,
    required this.isRightPanelVisible,
    required this.onHorizontalDragEnd,
    required this.onResetPanels,
    this.isDarkBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80, // Фиксированная высота для Stack
      child: ClipRect( // Обрезаем контент чтобы не было overflow
        child: GestureDetector(
          behavior: HitTestBehavior.translucent, // Позволяем тапам проходить к дочерним элементам
          onHorizontalDragEnd: onHorizontalDragEnd,
          child: Stack(
            children: [
              // Основной контейнер привычек (сдвигается при свайпе)
              AnimatedPositioned(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: isLeftPanelVisible ? 125.0 : (isRightPanelVisible ? -125.0 : 0.0),
                top: 0,
                right: isLeftPanelVisible ? -125.0 : (isRightPanelVisible ? 125.0 : 0.0),
                bottom: 0,
                child: Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    color: habit.getBackgroundColor(isDarkBackground),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: habit.isSkipped 
                          ? (isDarkBackground ? Colors.white.withOpacity(0.2) : AppColors.black20)
                          : (isDarkBackground ? Colors.white.withOpacity(0.1) : AppColors.black10),
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
                              // Круглый прогресс-бар с иконкой привычки
                              GestureDetector(
                                onTap: habit.onEditPressed,
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Круговой прогресс бар
                                      CircularProgressIndicator(
                                        value: habit.progressPercent,
                                        strokeWidth: 3,
                                        backgroundColor: isDarkBackground 
                                            ? Colors.white.withOpacity(0.15)
                                            : AppColors.black10,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          habit.isSkipped 
                                              ? (isDarkBackground ? Colors.white.withOpacity(0.4) : AppColors.black40)
                                              : habit.progressColor,
                                        ),
                                      ),
                                      // Внутренний круг с иконкой
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: habit.isSkipped 
                                              ? (isDarkBackground ? Colors.white.withOpacity(0.1) : AppColors.black10)
                                              : (habit.isCompleted 
                                                  ? AppColors.green40.withOpacity(0.2)
                                                  : (isDarkBackground ? Colors.white.withOpacity(0.9) : Colors.white)),
                                          shape: BoxShape.circle,
                                          border: habit.isCompleted 
                                              ? Border.all(color: AppColors.green40, width: 2)
                                              : null,
                                        ),
                                        child: Center(
                                          child: habit.isCompleted 
                                              ? Icon(
                                                  Icons.check,
                                                  color: AppColors.green40,
                                                  size: 20,
                                                )
                                              : Text(
                                                  habit.emoji,
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    color: habit.isSkipped ? AppColors.black40 : null,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              // Колонка с текстом и прогрессом
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Заголовок и streak
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            habit.title,
                                            style: AppFonts.bodyTitleMedium.copyWith(
                                              color: isDarkBackground 
                                                  ? (habit.isCompleted ? Colors.white : Colors.white)
                                                  : AppColors.black100,
                                              fontSize: 15,
                                              fontWeight: habit.isCompleted ? FontWeight.w600 : FontWeight.w500,
                                              decoration: habit.isCompleted ? TextDecoration.lineThrough : null,
                                              decorationColor: isDarkBackground ? Colors.white.withOpacity(0.5) : AppColors.black40,
                                              decorationThickness: 2,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        // Streak badge
                                        if (habit.streak > 0)
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDarkBackground 
                                                  ? AppColors.orange.withOpacity(0.2)
                                                  : AppColors.orange10,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.local_fire_department,
                                                  color: AppColors.orange,
                                                  size: 12,
                                                ),
                                                SizedBox(width: 2),
                                                Text(
                                                  '${habit.streak}',
                                                  style: AppFonts.bodyAlternative.copyWith(
                                                    color: AppColors.orange,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        // CHALLENGE тег
                                        if (habit.isChallenge)
                                          Container(
                                            margin: EdgeInsets.only(right: 6),
                                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  AppColors.blue100,
                                                  AppColors.blue100.withOpacity(0.8),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(6),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.blue100.withOpacity(0.3),
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              'CHALLENGE',
                                              style: AppFonts.bodyAlternative.copyWith(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        // Подпись статуса
                                        Expanded(
                                          child: Text(
                                            habit.statusText,
                                            style: AppFonts.bodyAlternative.copyWith(
                                              color: habit.getTextColor(isDarkBackground),
                                              fontSize: 11,
                                              fontWeight: FontWeight.normal,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
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
                            // Кнопка добавления шага (+)
                            GestureDetector(
                              onTap: habit.isCompleted || habit.isSkipped || habit.isFailed
                                  ? null 
                                  : () {
                                      // Вызываем с умным шагом
                                      final step = habit.smartIncrementStep;
                                      if (habit.onAddPressed != null) {
                                        // Передаем шаг через callback с параметром
                                        (habit.onAddPressed as void Function(int)?)?.call(step);
                                      } else {
                                        print('Add step pressed: ${habit.title} +$step');
                                      }
                                      // Возвращаем карточку после добавления шага
                                      onResetPanels();
                                    },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: habit.isCompleted 
                                      ? (isDarkBackground ? AppColors.green40.withOpacity(0.2) : AppColors.green10)
                                      : (isDarkBackground ? Colors.white.withOpacity(0.9) : Colors.white),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: habit.isCompleted 
                                        ? AppColors.green40
                                        : (isDarkBackground ? Colors.white.withOpacity(0.3) : AppColors.black10),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: habit.isCompleted
                                      ? Icon(
                                          Icons.check,
                                          color: AppColors.green40,
                                          size: 18,
                                        )
                                      : Icon(
                                          Icons.add,
                                          color: habit.isSkipped 
                                              ? (isDarkBackground ? Colors.white.withOpacity(0.5) : AppColors.black40)
                                              : (isDarkBackground ? AppColors.blue100 : AppColors.black100),
                                          size: 18,
                                        ),
                                ),
                              ),
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
                    color: isDarkBackground ? Colors.white.withOpacity(0.15) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkBackground ? Colors.white.withOpacity(0.2) : AppColors.black10,
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
                          onTap: () {
                            if (habit.onViewPressed != null) {
                              habit.onViewPressed!();
                            } else {
                              print('View pressed: ${habit.title}');
                              if (habit.isCompleted) {
                                print('Habit already completed - showing completion effects');
                              }
                            }
                            onResetPanels(); // Возвращаем карточку
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.visibility,
                                color: isDarkBackground ? Colors.white.withOpacity(0.7) : AppColors.black40,
                                size: 20,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'View',
                                style: AppFonts.bodyAlternative.copyWith(
                                  color: isDarkBackground ? Colors.white.withOpacity(0.7) : AppColors.black40,
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
                          color: isDarkBackground ? Colors.white.withOpacity(0.2) : AppColors.black10,
                        ),
                        // Правый столбик - галочка и Done
                        GestureDetector(
                          onTap: () {
                            if (habit.onDonePressed != null) {
                              habit.onDonePressed!();
                            } else {
                              print('Done pressed: ${habit.title}');
                              if (habit.isCompleted) {
                                print('Habit already completed - showing completion effects');
                              }
                            }
                            onResetPanels(); // Возвращаем карточку
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
                                  color: isDarkBackground ? Colors.white.withOpacity(0.7) : AppColors.black40,
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
              // Правая боковая панель (выдвигается при свайпе влево) - Fall и Skip
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
                    color: isDarkBackground ? Colors.white.withOpacity(0.15) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkBackground ? Colors.white.withOpacity(0.2) : AppColors.black10,
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
                          onTap: () {
                            if (habit.onFallPressed != null) {
                              habit.onFallPressed!();
                            } else {
                              print('Fall pressed: ${habit.title}');
                            }
                            onResetPanels(); // Возвращаем карточку
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
                                  color: isDarkBackground ? Colors.white.withOpacity(0.7) : AppColors.black40,
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
                          color: isDarkBackground ? Colors.white.withOpacity(0.2) : AppColors.black10,
                        ),
                        // Правый столбик - стрелка вправо и Skip
                        GestureDetector(
                          onTap: () {
                            if (habit.onSkipPressed != null) {
                              habit.onSkipPressed!();
                            } else {
                              print('Skip pressed: ${habit.title}');
                            }
                            onResetPanels(); // Возвращаем карточку
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_forward,
                                color: isDarkBackground ? Colors.white.withOpacity(0.8) : AppColors.black100,
                                size: 20,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Skip',
                                style: AppFonts.bodyAlternative.copyWith(
                                  color: isDarkBackground ? Colors.white.withOpacity(0.7) : AppColors.black40,
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
