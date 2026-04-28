import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';

/// Виджет месячного календаря с отображением прогресса по дням
/// Показывает сетку дней месяца с круговыми прогресс-барами как в WeekDaysList
class MonthCalendarWidget extends StatefulWidget {
  final DateTime? selectedDate;
  final DateTime? initialMonth;
  final Map<String, double> dailyProgress; // Ключ: YYYY-MM-DD, Значение: прогресс 0.0-1.0
  final Function(DateTime)? onDateSelected;
  final Function(DateTime)? onMonthChanged;

  const MonthCalendarWidget({
    Key? key,
    this.selectedDate,
    this.initialMonth,
    this.dailyProgress = const {},
    this.onDateSelected,
    this.onMonthChanged,
  }) : super(key: key);

  @override
  State<MonthCalendarWidget> createState() => _MonthCalendarWidgetState();
}

class _MonthCalendarWidgetState extends State<MonthCalendarWidget> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.initialMonth ?? DateTime.now();
    _selectedDate = widget.selectedDate ?? DateTime.now();
  }

  @override
  void didUpdateWidget(MonthCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != null && widget.selectedDate != oldWidget.selectedDate) {
      setState(() {
        _selectedDate = widget.selectedDate!;
      });
    }
    if (widget.initialMonth != null && widget.initialMonth != oldWidget.initialMonth) {
      setState(() {
        _currentMonth = widget.initialMonth!;
      });
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
    widget.onMonthChanged?.call(_currentMonth);
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
    widget.onMonthChanged?.call(_currentMonth);
  }

  List<DateTime> _getDaysInMonth() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    
    // Получаем день недели первого дня месяца (0 = понедельник для удобства)
    var firstWeekday = firstDay.weekday - 1; // 0 = Monday, 6 = Sunday
    
    // Создаем список всех дней для отображения (включая пустые дни до начала месяца)
    List<DateTime> days = [];
    
    // Добавляем пустые дни перед началом месяца
    for (int i = 0; i < firstWeekday; i++) {
      days.add(DateTime(0)); // Плейсхолдер для пустого дня
    }
    
    // Добавляем дни месяца
    for (int i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }
    
    return days;
  }

  String _dateKey(DateTime date) {
    if (date.year == 0) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isSelected(DateTime date) {
    return date.year == _selectedDate.year &&
           date.month == _selectedDate.month &&
           date.day == _selectedDate.day;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Заголовок с месяцем и навигацией
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: Icon(Icons.chevron_left, color: AppColors.black100),
                ),
                Text(
                  '${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
                  style: AppFonts.bodyTitleMedium.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black100,
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: Icon(Icons.chevron_right, color: AppColors.black100),
                ),
              ],
            ),
          ),
          
          // Дни недели
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekdayNames.map((day) => 
                SizedBox(
                  width: 40,
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: AppFonts.body.copyWith(
                      fontSize: 12,
                      color: AppColors.black40,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ).toList(),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Сетка дней
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 7,
              childAspectRatio: 0.75,
              children: days.map((date) {
                if (date.year == 0) {
                  return const SizedBox.shrink(); // Пустой день
                }
                
                final isSelected = _isSelected(date);
                final isToday = _isToday(date);
                final dateKey = _dateKey(date);
                final progress = widget.dailyProgress[dateKey] ?? 0.0;
                final isCompleted = progress >= 1.0;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                    widget.onDateSelected?.call(date);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.blue100.withOpacity(0.15)
                          : isToday
                              ? AppColors.blue10
                              : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Фоновый круг прогресса (серый)
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                value: 1.0,
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.black10),
                              ),
                            ),
                            // Заполнение прогресса
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isSelected 
                                      ? AppColors.blue100 
                                      : isCompleted 
                                          ? AppColors.green40 
                                          : AppColors.blue40,
                                ),
                              ),
                            ),
                            // Число дня
                            Text(
                              date.day.toString(),
                              style: AppFonts.headlineH5.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected 
                                    ? AppColors.blue100 
                                    : isToday 
                                        ? AppColors.blue100
                                        : AppColors.black100,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Диалог с месячным календарем
class MonthCalendarDialog extends StatelessWidget {
  final DateTime? selectedDate;
  final DateTime? initialMonth;
  final Map<String, double> dailyProgress;
  final Function(DateTime) onDateSelected;
  final Function(DateTime)? onMonthChanged;

  const MonthCalendarDialog({
    Key? key,
    this.selectedDate,
    this.initialMonth,
    required this.dailyProgress,
    required this.onDateSelected,
    this.onMonthChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: MonthCalendarWidget(
        selectedDate: selectedDate,
        initialMonth: initialMonth,
        dailyProgress: dailyProgress,
        onDateSelected: (date) {
          onDateSelected(date);
        },
        onMonthChanged: onMonthChanged,
      ),
    );
  }
}
