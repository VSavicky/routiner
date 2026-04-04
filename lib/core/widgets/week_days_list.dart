import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';

class WeekDaysList extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;

  const WeekDaysList({
    Key? key,
    this.selectedDate,
    required this.onDateSelected,
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
    if (widget.selectedDate != oldWidget.selectedDate) {
      setState(() {
        _selectedDate = widget.selectedDate;
      });
    }
  }

  void _generateAllWeeks() {
    final now = DateTime.now();
    _allWeeks = [];
    
    print('=== DEBUG: Current date: ${now.toString()} ===');
    
    // Генерируем недели за год до и после текущей даты
    for (int i = -26; i <= 26; i++) {
      final weekStart = now.add(Duration(days: i * 7));
      final startOfWeek = weekStart.subtract(Duration(days: weekStart.weekday - 1));
      final weekDays = List.generate(7, (dayIndex) => startOfWeek.add(Duration(days: dayIndex)));
      _allWeeks.add(weekDays);
      
      // Логируем текущую неделю
      if (i == 0) {
        print('=== DEBUG: Current week days: ===');
        for (int j = 0; j < weekDays.length; j++) {
          print('Day $j: ${weekDays[j].toString()} - ${_getDayName(weekDays[j].weekday)}');
        }
      }
    }
    
    // Находим индекс текущей недели
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    print('=== DEBUG: Current week start: ${currentWeekStart.toString()} ===');
    for (int i = 0; i < _allWeeks.length; i++) {
      final week = _allWeeks[i][0]; // Понедельник недели
      if (week.day == currentWeekStart.day &&
          week.month == currentWeekStart.month &&
          week.year == currentWeekStart.year) {
        _currentWeekIndex = i;
        print('=== DEBUG: Found current week at index: $i ===');
        break;
      }
    }
  }

  void _scrollToCurrentWeek() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final itemWidth = 56.0 * 7; // Ширина одной недели
        final targetOffset = _currentWeekIndex * itemWidth;
        final screenWidth = MediaQuery.of(context).size.width;
        final centerOffset = targetOffset - (screenWidth / 2) + (itemWidth / 2);
        
        print('=== DEBUG: Jumping to week $_currentWeekIndex, offset: $centerOffset ===');
        
        // Мгновенное позиционирование без анимации
        _scrollController.jumpTo(centerOffset);
      }
    });
  }

  bool _isDateSelected(DateTime date) {
    return _selectedDate != null &&
        date.day == _selectedDate!.day &&
        date.month == _selectedDate!.month &&
        date.year == _selectedDate!.year;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    print('=== DEBUG: Build method - Today: ${now.toString()} ===');
    print('=== DEBUG: Build method - Selected: ${_selectedDate.toString()} ===');
    
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
            width: 56 * 7, // 7 дней * (48px + 8px отступ) - убираем лишние отступы
            child: Row(
              children: weekDays.asMap().entries.map((entry) {
                final dayIndex = entry.key;
                final date = entry.value;
                final isSelected = _isDateSelected(date);
                final isToday = date.day == DateTime.now().day &&
                    date.month == DateTime.now().month &&
                    date.year == DateTime.now().year;
                
                // Логируем каждый день в текущей неделе
                if (weekIndex == _currentWeekIndex) {
                  print('=== DEBUG: Day ${date.day} - ${_getDayName(date.weekday)} - isSelected: $isSelected - isToday: $isToday ===');
                }
                
                return GestureDetector(
                  onTap: () {
                    print('=== DEBUG: Tapped on date: ${date.toString()} ===');
                    setState(() {
                      _selectedDate = date;
                    });
                    widget.onDateSelected(date);
                  },
                  child: Container(
                    width: 48,
                    height: 60, // Уменьшаем еще на 3px
                    margin: EdgeInsets.only(right: dayIndex < 6 ? 8 : 0), // Убираем отступ у последнего элемента
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: isSelected 
                            ? AppColors.blue100 
                            : isToday 
                                ? AppColors.blue100.withOpacity(0.5) // Прозрачность для текущего дня
                                : AppColors.black10,
                        width: isSelected 
                            ? 2 
                            : isToday 
                                ? 2 
                                : 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          date.day.toString(),
                          style: AppFonts.headlineH5.copyWith(
                            color: isSelected 
                                ? AppColors.blue100 
                                : isToday 
                                    ? AppColors.blue100.withOpacity(0.8) // Прозрачность для текста
                                    : AppColors.black100,
                            fontSize: 16, // Уменьшаем размер текста
                          ),
                        ),
                        SizedBox(height: 2), // Уменьшаем отступ еще на 1px
                        Text(
                          _getDayName(date.weekday),
                          style: AppFonts.body.copyWith(
                            color: isSelected 
                                ? AppColors.blue100 
                                : isToday 
                                    ? AppColors.blue100.withOpacity(0.6) // Прозрачность для текста
                                    : AppColors.black20,
                            fontSize: 14, // Уменьшаем размер текста
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }
}
