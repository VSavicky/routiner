import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/features/auth/presentation/widgets/auth_header.dart';

class CustomHabitScreen extends StatefulWidget {
  final String? moodEmoji;
  final String? moodLabel;
  final bool? isBadHabit;
  final String? selectedHabitName;
  final String? selectedHabitSubtitle;
  final String? selectedHabitEmoji;

  const CustomHabitScreen({
    super.key,
    this.moodEmoji,
    this.moodLabel,
    this.isBadHabit,
    this.selectedHabitName,
    this.selectedHabitSubtitle,
    this.selectedHabitEmoji,
  });

  @override
  State<CustomHabitScreen> createState() => _CustomHabitScreenState();
}

class _CustomHabitScreenState extends State<CustomHabitScreen> {
  int _selectedIconIndex = 0;
  final List<String> _iconEmojis = ['🚶', '📚', '💧', '🧘', '🏃', '😴', '🥗', '🎸', '✍️', '🎯'];
  final List<String> _iconNames = ['Walking', 'Reading', 'Water', 'Meditation', 'Running', 'Sleep', 'Healthy Food', 'Music', 'Writing', 'Target'];
  
  int _selectedColorIndex = 0;
  final List<Color> _colors = [
    Color(0xFFFFB3BA), Color(0xFFB3E5FC), Color(0xFFB3FFB3), Color(0xFFE5B3FF),
    Color(0xFFFFD8B3), Color(0xFFFFF4B3), Color(0xFFB3FFF4), Color(0xFFFFB3E5),
    Color(0xFFC4B3FF), Color(0xFFB3FFC4),
  ];
  final List<String> _colorNames = ['Pink', 'Blue', 'Green', 'Purple', 'Orange', 'Yellow', 'Turquoise', 'Rose', 'Lavender', 'Mint'];

  // Controller для названия привычки
  late TextEditingController _nameController;

  // Данные для GOAL
  int _frequency = 1;
  String _period = 'day';
  String _periodLabel = 'Daily';
  String _scheduleDetail = 'every day';

  // Данные для REMINDERS
  bool _remindersEnabled = true;
  List<String> _reminderTimes = ['09:30'];
  String _reminderPeriod = 'Every day';

  // Habit Type
  bool _isBuildHabit = true;

  // Target Goal
  int _targetValue = 1;
  String _targetUnit = 'times';

  final List<Map<String, String>> _targetUnits = [
    {'value': 'ml', 'label': 'ml', 'icon': '💧'},
    {'value': 'steps', 'label': 'steps', 'icon': '🚶'},
    {'value': 'min', 'label': 'min', 'icon': '⏱️'},
    {'value': 'hours', 'label': 'hours', 'icon': '🕐'},
    {'value': 'times', 'label': 'times', 'icon': '🔄'},
    {'value': 'pages', 'label': 'pages', 'icon': '📄'},
    {'value': 'km', 'label': 'km', 'icon': '📍'},
    {'value': 'cal', 'label': 'cal', 'icon': '🔥'},
  ];

  final List<Map<String, String>> _frequencyOptions = [
    {'value': '1', 'label': '1 time', 'detail': ''},
    {'value': '2', 'label': '2 times', 'detail': ''},
    {'value': '3', 'label': '3 times', 'detail': ''},
    {'value': '5', 'label': '5 times', 'detail': ''},
    {'value': '7', 'label': '7 times', 'detail': ''},
  ];

  final List<Map<String, String>> _periodOptions = [
    {'value': 'day', 'label': 'Daily', 'detail': 'every day'},
    {'value': 'week', 'label': 'Weekly', 'detail': 'per week'},
    {'value': 'month', 'label': 'Monthly', 'detail': 'per month'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.selectedHabitName ?? '');
    if (widget.selectedHabitEmoji != null) {
      int index = _iconEmojis.indexOf(widget.selectedHabitEmoji!);
      if (index != -1) _selectedIconIndex = index;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Icon',
                style: AppFonts.bodyTitleMedium.copyWith(
                  color: AppColors.black100,
                ),
              ),
              SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(_iconEmojis.length, (index) {
                  bool isSelected = _selectedIconIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIconIndex = index;
                      });
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.blue10 : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.blue100 : AppColors.black10,
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _iconEmojis[index],
                          style: TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Color',
                style: AppFonts.bodyTitleMedium.copyWith(
                  color: AppColors.black100,
                ),
              ),
              
              SizedBox(height: 20),
              
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(_colors.length, (index) {
                  bool isSelected = _selectedColorIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColorIndex = index;
                      });
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _colors[index],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.blue100 : Colors.transparent,
                          width: isSelected ? 3 : 0,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Icon(
                                Icons.check,
                                color: AppColors.black100,
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showGoalPicker() {
    // Временные переменные для picker
    int tempFrequency = _frequency;
    String tempPeriod = _period;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPickerState) {
            return Container(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Frequency',
                    style: AppFonts.bodyTitleMedium.copyWith(
                      color: AppColors.black100,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Выбор количества
                  Text(
                    'How many times?',
                    style: AppFonts.bodyAlternative.copyWith(
                      color: AppColors.black60,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _frequencyOptions.map((option) {
                      bool isSelected = tempFrequency.toString() == option['value'];
                      return GestureDetector(
                        onTap: () {
                          setPickerState(() {
                            tempFrequency = int.parse(option['value']!);
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.blue10 : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.blue100 : AppColors.black10,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          child: Text(
                            option['label']!,
                            style: AppFonts.bodyTitleMedium.copyWith(
                              fontSize: 14,
                              color: AppColors.black100,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  // Выбор периода
                  Text(
                    'How often?',
                    style: AppFonts.bodyAlternative.copyWith(
                      color: AppColors.black60,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _periodOptions.map((option) {
                      bool isSelected = tempPeriod == option['value'];
                      return GestureDetector(
                        onTap: () {
                          setPickerState(() {
                            tempPeriod = option['value']!;
                          });
                          // Обновляем основной state и закрываем
                          setState(() {
                            _frequency = tempFrequency;
                            _period = option['value']!;
                            _periodLabel = option['label']!;
                            _scheduleDetail = option['detail']!;
                          });
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.blue10 : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.blue100 : AppColors.black10,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          child: Text(
                            option['label']!,
                            style: AppFonts.bodyTitleMedium.copyWith(
                              fontSize: 14,
                              color: AppColors.black100,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // iOS стиль свитч
  Widget _buildIOSSwitch() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _remindersEnabled = !_remindersEnabled;
        });
      },
      child: Container(
        width: 50,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: _remindersEnabled ? AppColors.green : AppColors.black20,
        ),
        child: AnimatedAlign(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: _remindersEnabled ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.all(2),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTimePicker({int? index}) async {
    final List<String> periodOptions = ['Every day', 'Weekdays', 'Weekend', 'Only today'];
    String selectedPeriod = _reminderPeriod;
    TimeOfDay selectedTime = index != null
        ? TimeOfDay(
            hour: int.parse(_reminderTimes[index].split(':')[0]),
            minute: int.parse(_reminderTimes[index].split(':')[1]),
          )
        : const TimeOfDay(hour: 9, minute: 30);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPickerState) {
            return Container(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set Reminder',
                    style: AppFonts.bodyTitleMedium.copyWith(
                      color: AppColors.black100,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Time picker button
                  GestureDetector(
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: AppColors.blue100,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: AppColors.black100,
                                tertiary: AppColors.blue100,
                                onTertiary: Colors.white,
                              ),
                              textTheme: Theme.of(context).textTheme.copyWith(
                                displayLarge: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black100,
                                ),
                                displayMedium: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black100,
                                ),
                              ),
                            ),
                            child: MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                textScaleFactor: 0.8,
                              ),
                              child: child!,
                            ),
                          );
                        },
                      );
                      if (picked != null) {
                        setPickerState(() {
                          selectedTime = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.darkblue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time,
                            color: AppColors.blue100,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                            style: AppFonts.bodyTitleMedium.copyWith(
                              fontSize: 24,
                              color: AppColors.black100,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Repeat',
                    style: AppFonts.bodyAlternative.copyWith(
                      fontSize: 12,
                      color: AppColors.black60,
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: periodOptions.map((period) {
                      bool isSelected = selectedPeriod == period;
                      return GestureDetector(
                        onTap: () {
                          setPickerState(() {
                            selectedPeriod = period;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.blue10 : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.blue100 : AppColors.black10,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          child: Text(
                            period,
                            style: AppFonts.bodyTitleMedium.copyWith(
                              fontSize: 14,
                              color: AppColors.black100,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        final newTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                        setState(() {
                          _reminderPeriod = selectedPeriod;
                          if (index != null) {
                            _reminderTimes[index] = newTime;
                          } else {
                            _reminderTimes.add(newTime);
                          }
                        });
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue100,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: AppFonts.bodyTitleMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTargetUnitPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPickerState) {
            return Container(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Unit',
                    style: AppFonts.bodyTitleMedium.copyWith(
                      color: AppColors.black100,
                    ),
                  ),
                  SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _targetUnits.map((unit) {
                      bool isSelected = _targetUnit == unit['value'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _targetUnit = unit['value']!;
                          });
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.blue10 : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.blue100 : AppColors.black10,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                unit['icon'] ?? '🔄',
                                style: TextStyle(fontSize: 20),
                              ),
                              SizedBox(width: 8),
                              Text(
                                unit['label']!,
                                style: AppFonts.bodyTitleMedium.copyWith(
                                  fontSize: 14,
                                  color: AppColors.black100,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _addReminder() {
    _showTimePicker();
  }

  void _removeReminder(int index) {
    setState(() {
      _reminderTimes.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AuthHeader(
            title: 'Create Custom Habit',
            onBackPressed: () => Navigator.of(context).pop(),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    
                    Text(
                      'NAME',
                      style: AppFonts.bodyAlternative.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black100,
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    TextField(
                      controller: _nameController,
                      style: AppFonts.bodyTitleMedium.copyWith(
                        fontSize: 18,
                        height: 24 / 18,
                        color: AppColors.black100,
                      ),
                      decoration: InputDecoration(
                        hintText: 'New Habit',
                        hintStyle: AppFonts.bodyTitleMedium.copyWith(
                          fontSize: 18,
                          height: 24 / 18,
                          color: AppColors.black40,
                        ),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.black20),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.black20),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.black20),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    
                    SizedBox(height: 30),
                    
                    Text(
                      'ICON AND COLOR',
                      style: AppFonts.bodyAlternative.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black100,
                      ),
                    ),
                    
                    SizedBox(height: 5),
                    
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _showIconPicker,
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.black10,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _iconEmojis[_selectedIconIndex],
                                        style: TextStyle(fontSize: 24),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _iconNames[_selectedIconIndex],
                                          style: AppFonts.bodyTitleMedium.copyWith(
                                            color: AppColors.black100,
                                          ),
                                        ),
                                        Text(
                                          'Icon',
                                          style: AppFonts.bodyAlternative.copyWith(
                                            fontSize: 12,
                                            height: 16 / 12,
                                            color: AppColors.black40,
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
                        
                        SizedBox(width: 12),
                        
                        Expanded(
                          child: GestureDetector(
                            onTap: _showColorPicker,
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.black10,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _colors[_selectedColorIndex],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _colorNames[_selectedColorIndex],
                                          style: AppFonts.bodyTitleMedium.copyWith(
                                            color: AppColors.black100,
                                          ),
                                        ),
                                        Text(
                                          'Color',
                                          style: AppFonts.bodyAlternative.copyWith(
                                            fontSize: 12,
                                            height: 16 / 12,
                                            color: AppColors.black40,
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
                    
                    SizedBox(height: 20),
                    
                    // TARGET GOAL секция
                    Text(
                      'TARGET GOAL',
                      style: AppFonts.bodyAlternative.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black100,
                      ),
                    ),
                    
                    SizedBox(height: 5),
                    
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.black10,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Preview как будет выглядеть
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.darkblue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '0',
                                  style: AppFonts.bodyTitleMedium.copyWith(
                                    fontSize: 18,
                                    color: AppColors.black100,
                                  ),
                                ),
                                Text(
                                  '/',
                                  style: AppFonts.bodyTitleMedium.copyWith(
                                    fontSize: 18,
                                    color: AppColors.black40,
                                  ),
                                ),
                                Text(
                                  '$_targetValue',
                                  style: AppFonts.bodyTitleMedium.copyWith(
                                    fontSize: 18,
                                    color: AppColors.blue100,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  _targetUnit,
                                  style: AppFonts.bodyAlternative.copyWith(
                                    fontSize: 14,
                                    color: AppColors.black60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12),
                          // Target value input + unit selector
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  style: AppFonts.bodyTitleMedium.copyWith(
                                    color: AppColors.black100,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '500',
                                    hintStyle: AppFonts.bodyTitleMedium.copyWith(
                                      color: AppColors.black40,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.darkblue,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.all(12),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _targetValue = int.tryParse(value) ?? 1;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: GestureDetector(
                                  onTap: () => _showTargetUnitPicker(),
                                  child: Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.darkblue,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _targetUnits.firstWhere(
                                            (u) => u['value'] == _targetUnit,
                                            orElse: () => _targetUnits[4],
                                          )!['icon']!,
                                          style: TextStyle(fontSize: 20),
                                        ),
                                        Text(
                                          _targetUnit,
                                          style: AppFonts.bodyTitleMedium.copyWith(
                                            fontSize: 14,
                                            color: AppColors.black100,
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color: AppColors.black40,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // GOAL секция
                    Text(
                      'GOAL',
                      style: AppFonts.bodyAlternative.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black100,
                      ),
                    ),
                    
                    SizedBox(height: 5),
                    
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.black10,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$_frequency ${_frequency == 1 ? 'time' : 'times'}',
                                      style: AppFonts.bodyTitleMedium.copyWith(
                                        color: AppColors.black100,
                                      ),
                                    ),
                                    Text(
                                      _period == 'day' ? 'or more per day' : (_period == 'week' ? 'or more per week' : 'or more per month'),
                                      style: AppFonts.bodyAlternative.copyWith(
                                        fontSize: 12,
                                        height: 16 / 12,
                                        color: AppColors.black40,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Иконка карандаша
                              GestureDetector(
                                onTap: _showGoalPicker,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.darkblue,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.black10,
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.edit,
                                      color: AppColors.black100,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          // Контейнер с расписанием (darkblue) - теперь кликабельный
                          GestureDetector(
                            onTap: _showGoalPicker,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.darkblue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _periodLabel,
                                    style: AppFonts.bodyTitleMedium.copyWith(
                                      fontSize: 14,
                                      color: AppColors.black100,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    _scheduleDetail,
                                    style: AppFonts.bodyAlternative.copyWith(
                                      fontSize: 12,
                                      color: AppColors.black60,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // REMINDERS секция
                    Text(
                      'REMINDERS',
                      style: AppFonts.bodyAlternative.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black100,
                      ),
                    ),
                    
                    SizedBox(height: 5),
                    
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.black10,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Remember to set off time for a workout today.',
                                  style: AppFonts.bodyAlternative.copyWith(
                                    fontSize: 12,
                                    height: 16 / 12,
                                    color: AppColors.black60,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              // iOS стиль свитча
                              _buildIOSSwitch(),
                            ],
                          ),
                          SizedBox(height: 12),
                          // Список времен напоминаний
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _reminderTimes.asMap().entries.map((entry) {
                              final index = entry.key;
                              final time = entry.value;
                              return GestureDetector(
                                onTap: () => _showTimePicker(index: index),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkblue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        time,
                                        style: AppFonts.bodyTitleMedium.copyWith(
                                          fontSize: 14,
                                          color: AppColors.black100,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        _reminderPeriod,
                                        style: AppFonts.bodyAlternative.copyWith(
                                          fontSize: 12,
                                          color: AppColors.black60,
                                        ),
                                      ),
                                      if (_reminderTimes.length > 1)
                                        GestureDetector(
                                          onTap: () => _removeReminder(index),
                                          child: Padding(
                                            padding: EdgeInsets.only(left: 8),
                                            child: Icon(
                                              Icons.close,
                                              size: 16,
                                              color: AppColors.black40,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 8),
                    
                    // Кнопка Add Reminder
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _addReminder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.black100,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                            side: BorderSide(
                              color: AppColors.black10,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          'Add Reminder',
                          style: AppFonts.bodyTitleMedium.copyWith(
                            fontSize: 14,
                            color: AppColors.black100,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Habit Type заголовок
                    Text(
                      'HABIT TYPE',
                      style: AppFonts.bodyAlternative.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black100,
                      ),
                    ),
                    
                    SizedBox(height: 5),
                    
                    // Toggle Build/Quit
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.black10,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isBuildHabit = true;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isBuildHabit ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(36),
                                ),
                                child: Center(
                                  child: Text(
                                    'Build',
                                    style: AppFonts.bodyTitleMedium.copyWith(
                                      fontSize: 14,
                                      color: _isBuildHabit ? AppColors.blue100 : AppColors.black100,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isBuildHabit = false;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_isBuildHabit ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(36),
                                ),
                                child: Center(
                                  child: Text(
                                    'Quit',
                                    style: AppFonts.bodyTitleMedium.copyWith(
                                      fontSize: 14,
                                      color: !_isBuildHabit ? AppColors.blue100 : AppColors.black100,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // MOTIVATION секция
                    Text(
                      'MOTIVATION',
                      style: AppFonts.bodyAlternative.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black100,
                      ),
                    ),
                    
                    SizedBox(height: 5),
                    
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.black10,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        maxLines: 3,
                        style: AppFonts.bodyAlternative.copyWith(
                          fontSize: 14,
                          color: AppColors.black100,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Why is this important to you?',
                          hintStyle: AppFonts.bodyAlternative.copyWith(
                            fontSize: 14,
                            color: AppColors.black40,
                          ),
                          filled: true,
                          fillColor: AppColors.darkblue,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          
          // Кнопка Create Habit зафиксирована внизу
          Padding(
            padding: EdgeInsets.only(left: 24, right: 24, bottom: 40),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue100,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                child: Text(
                  'Create Habit',
                  style: AppFonts.bodyTitleMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
