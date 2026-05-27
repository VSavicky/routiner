import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/core/constants/default_habits.dart';
import 'package:routiner/features/habits/data/models/habit_model.dart';
import 'package:routiner/features/habits/data/models/habit_log_model.dart';
import 'package:routiner/features/habits/data/repositories/habit_repository.dart';
import 'package:routiner/l10n/app_localizations.dart';

/// Экран деталей привычки
class HabitDetailScreen extends StatefulWidget {
  final HabitModel? habit; // null если привычка еще не добавлена (системная)
  final DefaultHabit? defaultHabit; // системная привычка из DefaultHabits
  final String? challengeId; // ID челленджа если привычка из челленджа
  final String? challengeName; // Имя челленджа

  const HabitDetailScreen({
    super.key,
    this.habit,
    this.defaultHabit,
    this.challengeId,
    this.challengeName,
  }) : assert(habit != null || defaultHabit != null,
            'Either habit or defaultHabit must be provided');

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  final HabitRepository _habitRepository = HabitRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  bool _isAdded = false;
  Map<int, double> _dailyProgress = {}; // прогресс по дням (последние 30 дней)
  HabitLogModel? _todayLog;

  // Данные привычки (либо из HabitModel, либо из DefaultHabit)
  late String _name;
  late String _localizedHabitName; // Локализованное название
  late String _emoji;
  late String _description;
  late String _localizedDescription; // Локализованное описание
  late Color _color;
  late int _targetValue;
  late String _targetUnit;
  late String _habitType;

  @override
  void initState() {
    super.initState();
    _initHabitData();
    _loadData();
  }

  void _initHabitData() {
    if (widget.habit != null) {
      // Пользовательская привычка
      _name = widget.habit!.name;
      _emoji = widget.habit!.emoji;
      _description = widget.habit!.motivation ?? '';
      _color = widget.habit!.colorValue;
      _targetValue = widget.habit!.targetValue > 0 ? widget.habit!.targetValue : 1;
      _targetUnit = widget.habit!.targetUnit.isNotEmpty
          ? widget.habit!.targetUnit
          : 'times';
      _habitType = widget.habit!.habitType;
      _isAdded = true;
    } else if (widget.defaultHabit != null) {
      // Системная привычка
      _name = widget.defaultHabit!.name;
      _emoji = widget.defaultHabit!.emoji;
      _description = widget.defaultHabit!.motivation ?? widget.defaultHabit!.subtitle;
      _color = widget.defaultHabit!.color;
      _targetValue = 1;
      _targetUnit = 'times';
      _habitType = 'build';
      _isAdded = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Локализация названия и описания происходит здесь, когда контекст доступен
    _localizedHabitName = _getLocalizedHabitName(_name);
    _localizedDescription = _description.isNotEmpty 
        ? _description 
        : context.l10n.translate('noDescription');
  }

  /// Локализация названия привычки
  String _getLocalizedHabitName(String habitName) {
    switch (habitName.toLowerCase()) {
      case 'cycling':
        return context.l10n.translate('cycling');
      case 'drink water':
        return context.l10n.translate('drinkWater');
      case 'daily workout':
        return context.l10n.translate('dailyWorkout');
      case 'take 8k steps':
        return context.l10n.translate('take8KSteps');
      case 'meditate':
        return context.l10n.translate('meditate');
      case 'morning stretch':
        return context.l10n.translate('morningStretch');
      case 'read book':
        return context.l10n.translate('readBook');
      case 'eat vegetables':
        return context.l10n.translate('eatVegetables');
      case 'cook at home':
        return context.l10n.translate('cookAtHome');
      case 'no phone 1h before bed':
        return context.l10n.translate('noPhone1hBeforeBed');
      case 'read instead':
        return context.l10n.translate('readInstead');
      case 'no sugar':
        return context.l10n.translate('noSugar');
      case 'max 1 coffee':
        return context.l10n.translate('max1Coffee');
      case 'drink herbal tea':
        return context.l10n.translate('drinkHerbalTea');
      case 'complete 3 priorities':
        return context.l10n.translate('complete3Priorities');
      case 'no social media at work':
        return context.l10n.translate('noSocialMediaAtWork');
      case 'max 1h tv/netflix':
        return context.l10n.translate('max1hTvNetflix');
      case 'go for a walk':
        return context.l10n.translate('goForAWalk');
      case 'run':
        return context.l10n.translate('run');
      case 'walk':
        return context.l10n.translate('walk');
      case 'read':
        return context.l10n.translate('read');
      case 'less sugar':
        return context.l10n.translate('lessSugar');
      case 'stop procrastinating':
        return context.l10n.translate('stopProcrastinating');
      default:
        return habitName;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Если привычка добавлена, загружаем прогресс
      if (widget.habit?.id != null) {
        await _loadHabitProgress(user.uid, widget.habit!.id!);
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('[HABIT DETAIL ERROR] $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadHabitProgress(String userId, String habitId) async {
    // Загружаем прогресс за последние 30 дней
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 29));

    final logsStream = _habitRepository.getHabitLogsForPeriod(
      habitId,
      startDate,
      now,
    );

    final logs = await logsStream.first;

    // Формируем мапу прогресса по дням (1-30)
    final progressMap = <int, double>{};
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: 29 - i));
      final dayNumber = i + 1;

      // Ищем лог для этой даты
      final log = logs.firstWhere(
        (l) =>
            l.date.year == date.year &&
            l.date.month == date.month &&
            l.date.day == date.day,
        orElse: () => HabitLogModel(
          id: '',
          habitId: habitId,
          userId: userId,
          date: date,
          status: HabitStatus.pending,
          value: 0,
        ),
      );

      // Вычисляем прогресс (0.0 - 1.0)
      final targetVal = _targetValue > 0 ? _targetValue : 1;
      final logValue = log.isCompleted ? targetVal : (log.value ?? 0);
      progressMap[dayNumber] = (logValue / targetVal).clamp(0.0, 1.0);
    }

    // Загружаем сегодняшний лог отдельно
    final todayLogs =
        await _habitRepository.getHabitLogsForDate(userId, now);
    final todayLog = todayLogs.firstWhere(
      (l) => l.habitId == habitId,
      orElse: () => HabitLogModel(
        id: '',
        habitId: habitId,
        userId: userId,
        date: now,
        status: HabitStatus.pending,
        value: 0,
      ),
    );

    if (mounted) {
      setState(() {
        _dailyProgress = progressMap;
        _todayLog = todayLog;
      });
    }
  }

  /// Метод для перезагрузки данных (вызывается при возврате с других экранов)
  void reload() {
    _loadData();
  }

  /// Локализация единицы измерения
  String _getLocalizedUnit(String unit) {
    switch (unit.toLowerCase()) {
      case 'times':
        return context.l10n.translate('times');
      case 'steps':
        return context.l10n.translate('steps');
      case 'min':
        return context.l10n.translate('min');
      case 'hour':
      case 'hours':
        return context.l10n.translate('hours');
      case 'pages':
        return context.l10n.translate('pages');
      case 'ml':
        return context.l10n.translate('ml');
      case 'km':
        return context.l10n.translate('km');
      case 'cal':
      case 'kcal':
        return 'kcal';
      default:
        return unit;
    }
  }

  /// Локализация типа привычки
  String _getLocalizedHabitType(String type) {
    switch (type.toLowerCase()) {
      case 'build':
        return context.l10n.translate('building');
      case 'quit':
        return context.l10n.translate('quitting');
      default:
        return type;
    }
  }

  /// Локализация подписи цели
  String _getLocalizedTargetLabel() {
    switch (_habitType.toLowerCase()) {
      case 'build':
        return context.l10n.translate('buildingGoal');
      case 'quit':
        return context.l10n.translate('quittingGoal');
      default:
        return context.l10n.translate('target');
    }
  }

  Future<void> _addHabit() async {
    if (widget.defaultHabit == null) return;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Создаем привычку из системной
      final newHabit = HabitModel(
        userId: user.uid,
        name: widget.defaultHabit!.name,
        emoji: widget.defaultHabit!.emoji,
        color: HabitModel.colorToHex(widget.defaultHabit!.color),
        habitType: 'build',
        motivation: widget.defaultHabit!.motivation ?? widget.defaultHabit!.subtitle,
        isDefaultHabit: true,
        defaultHabitId: widget.defaultHabit!.id,
        challengeId: widget.challengeId,
      );

      await _habitRepository.createHabit(newHabit);

      if (mounted) {
        setState(() => _isAdded = true);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.trArgs('addedToYourHabits', {'name': _name})),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      print('[ADD HABIT ERROR] $e');
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.translate('failedToAddHabit')),
              backgroundColor: Colors.red,
            ),
          );
      }
    }
  }

  Future<void> _deleteHabit() async {
    if (widget.habit?.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Иконка
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              // Заголовок
              Text(
                context.l10n.translate('deleteHabit'),
                style: AppFonts.bodyTitleMedium.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black100,
                ),
              ),
              const SizedBox(height: 12),
              // Описание
              Text(
                context.l10n.translate('deleteHabitConfirmation').replaceAll('{name}', _name),
                textAlign: TextAlign.center,
                style: AppFonts.bodyTitleMedium.copyWith(
                  fontSize: 14,
                  color: AppColors.black60,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // Кнопки
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black10,
                        foregroundColor: AppColors.black100,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                        child: Text(
                          context.l10n.translate('cancel'),
                          style: AppFonts.bodyTitleMedium.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                        child: Text(
                          context.l10n.translate('delete'),
                          style: AppFonts.bodyTitleMedium.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
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
    );

    if (confirmed != true) return;

    try {
      await _habitRepository.deleteHabit(widget.habit!.id!);

      if (mounted) {
        Navigator.pop(context, true); // true = удалено
      }
    } catch (e) {
      print('[DELETE HABIT ERROR] $e');
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.translate('failedToDeleteHabit')),
              backgroundColor: Colors.red,
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Используем цвет привычки для градиента или фиолетовый по умолчанию
    final gradientColors = [
      _color.computeLuminance() > 0.5
          ? AppColors.purple
          : _color.withOpacity(0.8),
      AppColors.blue,
    ];

    return WillPopScope(
      onWillPop: () async {
        // Обновляем данные на главном экране при возврате
        Navigator.of(context).pop(true); // true = данные изменены
        return false;
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
              stops: const [0.0, 1.0],
            ),
          ),
          child: SafeArea(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 8, bottom: 20),
                                child: Row(
                                  children: [
                                    // Back button
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        icon: Icon(
                                          Icons.arrow_back_ios_new,
                                          size: 18,
                                          color: gradientColors[0],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Habit icon
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    _emoji,
                                    style: const TextStyle(fontSize: 40),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Title
                              Text(
                                _localizedHabitName,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Challenge badge (if from challenge)
                              if (widget.challengeName != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.emoji_events,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${context.l10n.translate('from')}: ${widget.challengeName}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              if (widget.challengeName != null)
                                const SizedBox(height: 16),

                              // Description
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _localizedDescription,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    height: 1.5,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Target info
                              Row(
                                children: [
                                  _buildInfoCard(
                                    icon: Icons.track_changes,
                                    label: _getLocalizedTargetLabel(),
                                    value: '$_targetValue ${_getLocalizedUnit(_targetUnit)}',
                                  ),
                                  const SizedBox(width: 12),
                                  _buildInfoCard(
                                    icon: _habitType == 'build'
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    label: context.l10n.translate('type'),
                                    value: _getLocalizedHabitType(_habitType),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // Today's progress (if added)
                              if (_isAdded && _todayLog != null) ...[
                                Text(
                                  context.l10n.translate('todayProgress'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildTodayProgress(),
                                const SizedBox(height: 32),
                              ],

                              // Last 30 days
                              if (_isAdded) ...[
                                Text(
                                  context.l10n.translate('last30Days'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildDaysList(),
                                const SizedBox(height: 32),
                              ],

                              // Add/Delete button
                              if (_isAdded)
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton.icon(
                                    onPressed: _deleteHabit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.red,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(28),
                                      ),
                                    ),
                                    icon: const Icon(Icons.delete_outline),
                                    label: Text(
                                      context.l10n.translate('deleteHabit'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton.icon(
                                    onPressed: _addHabit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.purple,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(28),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add),
                                    label: Text(
                                      context.l10n.translate('addToMyHabits'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayProgress() {
    final isCompleted = _todayLog?.isCompleted ?? false;
    final currentValue = isCompleted ? _targetValue : (_todayLog?.value ?? 0);
    final progress = _targetValue > 0
        ? (currentValue / _targetValue).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$currentValue / $_targetValue ${_getLocalizedUnit(_targetUnit)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isCompleted)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 28,
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysList() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 30,
        itemBuilder: (context, index) {
          final dayNumber = index + 1;
          final progress = _dailyProgress[dayNumber] ?? 0.0;
          final isCompleted = progress >= 1.0;

          // Вычисляем дату для этого дня
          final date = DateTime.now().subtract(Duration(days: 29 - index));
          final isToday = index == 29;

          return GestureDetector(
            onTap: () {
              // TODO: Показать детали за этот день
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Circular progress
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background
                        Container(
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.blue.withOpacity(0.3)
                                : isCompleted
                                    ? AppColors.green.withOpacity(0.15)
                                    : Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                        // Progress indicator
                        Padding(
                          padding: const EdgeInsets.all(3),
                          child: CircularProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            strokeWidth: 3,
                            backgroundColor: Colors.white.withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted
                                  ? AppColors.green
                                  : progress > 0
                                      ? AppColors.orange
                                      : Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                        // Day number
                        Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight:
                                  isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Weekday
                  Text(
                    _getWeekdayShort(date.weekday),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getWeekdayShort(int weekday) {
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return days[weekday - 1];
  }
}
