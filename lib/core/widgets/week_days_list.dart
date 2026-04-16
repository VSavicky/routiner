import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';

class WeekDaysList extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;
  final Map<String, double> dailyProgress; // Ключ: YYYY-MM-DD, Значение: прогресс 0.0-1.0

  const WeekDaysList({
    Key? key,
    this.selectedDate,
    required this.onDateSelected,
    this.dailyProgress = const {},
  }) : super(key: key);

  @override
  State<WeekDaysList> createState() => _WeekDaysListState();
}

class _WeekDaysListState extends State<WeekDaysList> {
  late ScrollController _scrollController;
  late List<List<DateTime>> _allWeeks;
  late int _currentWeekIndex;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _selectedDate = widget.selectedDate ?? DateTime.now(); // Устанавливаем текущую дату если не выбрана
    _generateAllWeeks();
    _scrollToCurrentWeek();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WeekDaysList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Обновляем только если передана новая валидная дата отличная от текущей
    if (widget.selectedDate != null && 
        widget.selectedDate != oldWidget.selectedDate) {
      setState(() {
        _selectedDate = widget.selectedDate;
      });
    }
  }

  void _generateAllWeeks() {
    final now = DateTime.now();
    _allWeeks = [];
    
    // Генерируем недели за год до и после текущей даты
    for (int i = -26; i <= 26; i++) {
      final weekStart = now.add(Duration(days: i * 7));
      final startOfWeek = weekStart.subtract(Duration(days: weekStart.weekday - 1));
      final weekDays = List.generate(7, (dayIndex) => startOfWeek.add(Duration(days: dayIndex)));
      _allWeeks.add(weekDays);
    }
    
    // Находим индекс текущей недели
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    for (int i = 0; i < _allWeeks.length; i++) {
      final week = _allWeeks[i][0]; // Понедельник недели
      if (week.day == currentWeekStart.day &&
          week.month == currentWeekStart.month &&
          week.year == currentWeekStart.year) {
        _currentWeekIndex = i;
        break;
      }
    }
  }

  void _scrollToCurrentWeek() {
    // Используем несколько попыток прокрутки для надежности
    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: 100 * i), () {
        if (_scrollController.hasClients) {
          final dayWidth = 50.0; // Ширина одного дня (44 + 6 margin)
          final itemWidth = dayWidth * 7; // Ширина одной недели
          final targetOffset = _currentWeekIndex * itemWidth;
          final screenWidth = MediaQuery.of(context).size.width;
          final centerOffset = targetOffset - (screenWidth / 2) + (itemWidth / 2);
          
          // Мгновенное позиционирование без анимации
          _scrollController.jumpTo(centerOffset.clamp(0.0, _scrollController.position.maxScrollExtent));
        }
      });
    }
  }

  bool _isDateSelected(DateTime date) {
    return _selectedDate != null &&
        date.day == _selectedDate!.day &&
        date.month == _selectedDate!.month &&
        date.year == _selectedDate!.year;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      width: double.infinity,
      padding: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _allWeeks.length,
        itemBuilder: (context, weekIndex) {
          final weekDays = _allWeeks[weekIndex];
          
          return Container(
            width: 50 * 7, // 7 дней * (44px + 6px отступ)
            child: Row(
              children: weekDays.asMap().entries.map((entry) {
                final dayIndex = entry.key;
                final date = entry.value;
                final isSelected = _isDateSelected(date);
                final isToday = date.day == DateTime.now().day &&
                    date.month == DateTime.now().month &&
                    date.year == DateTime.now().year;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                    widget.onDateSelected(date);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: EdgeInsets.only(right: dayIndex < 6 ? 6 : 0, top: 2, bottom: 2),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.blue100.withOpacity(0.15)  // Синий фон для выбранного
                          : isToday 
                              ? Colors.white  // Белый фон для сегодня
                              : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected 
                            ? AppColors.blue100  // Яркая синяя рамка для выбранного
                            : isToday 
                                ? AppColors.blue40  // Светлая рамка для сегодня
                                : Colors.transparent,
                        width: isSelected ? 2.5 : (isToday ? 1.5 : 0),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.blue100.withOpacity(0.3),
                                blurRadius: 6,
                                spreadRadius: 1,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : isToday
                              ? [
                                  BoxShadow(
                                    color: AppColors.black10.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : null,
                    ),
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.white : Colors.transparent,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Круговой прогресс фон
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: CircularProgressIndicator(
                                  value: 1.0,
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.black10),
                                ),
                              ),
                              // Круговой прогресс заполнение
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: CircularProgressIndicator(
                                  value: widget.dailyProgress[_dateKey(date)] ?? 0.0,
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isSelected 
                                        ? AppColors.blue100 
                                        : AppColors.blue40,
                                  ),
                                ),
                              ),
                              // Число дня
                              Text(
                                date.day.toString(),
                                style: AppFonts.headlineH5.copyWith(
                                  color: isSelected 
                                      ? AppColors.blue100 
                                      : isToday 
                                          ? AppColors.blue100.withOpacity(0.8)
                                          : AppColors.black100,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  // Форматирование даты в ключ YYYY-MM-DD для Map
  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
