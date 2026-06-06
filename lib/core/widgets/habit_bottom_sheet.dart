import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/features/create_habit/presentation/screens/custom_habit_screen.dart';
import 'package:routiner/l10n/app_localizations.dart';

class LocalizedDefaultHabit {
  final String id;
  final String name;
  final String emoji;
  final String subtitle;
  final Color color;
  final int targetValue;
  final String targetUnit;
  final String unitLabel;
  final int frequency;
  final String period;
  final bool isGoodHabit;
  final String? motivation;
  final String? reminderTime;

  const LocalizedDefaultHabit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.subtitle,
    required this.color,
    required this.targetValue,
    required this.targetUnit,
    required this.unitLabel,
    this.frequency = 1,
    this.period = 'day',
    this.isGoodHabit = true,
    this.motivation,
    this.reminderTime,
  });
}

class LocalizedDefaultHabits {
  static List<LocalizedDefaultHabit> getGoodHabits(BuildContext context) {
    return [
      LocalizedDefaultHabit(
        id: 'walk',
        name: context.l10n.translate('walk'),
        emoji: '🚶',
        subtitle: '10,000 ${context.l10n.translate('steps')}',
        color: const Color(0xFFFFB3BA),
        targetValue: 10000,
        targetUnit: 'steps',
        unitLabel: 'steps',
        motivation: 'walkMotivation',
        reminderTime: '08:00',
      ),
      LocalizedDefaultHabit(
        id: 'read',
        name: context.l10n.translate('read'),
        emoji: '📚',
        subtitle: '30 ${context.l10n.translate('pages')}',
        color: const Color(0xFFB3E5FC),
        targetValue: 30,
        targetUnit: 'pages',
        unitLabel: 'pages',
        motivation: 'readMotivation',
        reminderTime: '21:00',
      ),
      LocalizedDefaultHabit(
        id: 'water',
        name: context.l10n.translate('drinkWater'),
        emoji: '💧',
        subtitle: '2,000 ${context.l10n.translate('ml')}',
        color: const Color(0xFFB3FFB3),
        targetValue: 2000,
        targetUnit: 'ml',
        unitLabel: 'ml',
        motivation: 'waterMotivation',
        reminderTime: '09:00',
      ),
      LocalizedDefaultHabit(
        id: 'meditate',
        name: context.l10n.translate('meditate'),
        emoji: '🧘',
        subtitle: '15 ${context.l10n.translate('min')}',
        color: const Color(0xFFE5B3FF),
        targetValue: 15,
        targetUnit: 'min',
        unitLabel: 'min',
        motivation: 'meditateMotivation',
      ),
      LocalizedDefaultHabit(
        id: 'run',
        name: context.l10n.translate('run'),
        emoji: '🏃',
        subtitle: '5 ${context.l10n.translate('km')}',
        color: const Color(0xFFFFD8B3),
        targetValue: 5,
        targetUnit: 'km',
        unitLabel: 'km',
        motivation: 'runMotivation',
      ),
      LocalizedDefaultHabit(
        id: 'sleep',
        name: context.l10n.translate('sleepEarly'),
        emoji: '😴',
        subtitle: '8 ${context.l10n.translate('hours')}',
        color: const Color(0xFFFFF4B3),
        targetValue: 8,
        targetUnit: 'hours',
        unitLabel: 'hours',
        motivation: 'sleepMotivation',
      ),
      LocalizedDefaultHabit(
        id: 'workout',
        name: context.l10n.translate('workout'),
        emoji: '💪',
        subtitle: '45 ${context.l10n.translate('min')}',
        color: const Color(0xFFFFB3E5),
        targetValue: 45,
        targetUnit: 'min',
        unitLabel: 'min',
        motivation: 'workoutMotivation',
      ),
      LocalizedDefaultHabit(
        id: 'journal',
        name: context.l10n.translate('journal'),
        emoji: '✍️',
        subtitle: '1 ${context.l10n.translate('entry')}',
        color: const Color(0xFFB3FFF4),
        targetValue: 1,
        targetUnit: 'times',
        unitLabel: 'times',
        motivation: 'journalMotivation',
      ),
    ];
  }

  static List<LocalizedDefaultHabit> getBadHabits(BuildContext context) {
    return [
      LocalizedDefaultHabit(
        id: 'smoke',
        name: context.l10n.translate('quitSmoking'),
        emoji: '🚭',
        subtitle: '0 ${context.l10n.translate('cigarettes')}',
        color: const Color(0xFFFFB3BA),
        targetValue: 0,
        targetUnit: 'times',
        unitLabel: 'cigarettes',
        isGoodHabit: false,
        motivation: 'smokeMotivation',
      ),
      LocalizedDefaultHabit(
        id: 'sugar',
        name: context.l10n.translate('lessSugar'),
        emoji: '🍰',
        subtitle: 'Max 25g',
        color: const Color(0xFFFFD8B3),
        targetValue: 25,
        targetUnit: 'cal',
        unitLabel: 'cal',
        isGoodHabit: false,
        motivation: 'sugarMotivation',
      ),
      LocalizedDefaultHabit(
        id: 'social',
        name: context.l10n.translate('lessSocialMedia'),
        emoji: '📱',
        subtitle: 'Max 30 ${context.l10n.translate('min')}',
        color: const Color(0xFFB3E5FC),
        targetValue: 30,
        targetUnit: 'min',
        unitLabel: 'min',
        isGoodHabit: false,
        motivation: 'socialMotivation',
      ),
      LocalizedDefaultHabit(
        id: 'alcohol',
        name: context.l10n.translate('noAlcohol'),
        emoji: '🍷',
        subtitle: '0 ${context.l10n.translate('times')}',
        color: const Color(0xFFE5B3FF),
        targetValue: 0,
        targetUnit: 'times',
        unitLabel: 'drinks',
        isGoodHabit: false,
        motivation: 'alcoholMotivation',
      ),
      LocalizedDefaultHabit(
        id: 'procrastinate',
        name: context.l10n.translate('stopProcrastinating'),
        emoji: '⏰',
        subtitle: context.l10n.translate('completeTask'),
        color: const Color(0xFFFFF4B3),
        targetValue: 1,
        targetUnit: 'times',
        unitLabel: 'tasks',
        isGoodHabit: false,
        motivation: 'procrastinateMotivation',
      ),
    ];
  }

  static List<LocalizedDefaultHabit> getByType(bool isGoodHabit, BuildContext context) {
    return isGoodHabit ? getGoodHabits(context) : getBadHabits(context);
  }
}

class HabitBottomSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String iconPath;
  final bool isBadHabbit;
  final VoidCallback onClose;
  final VoidCallback? onHabitCreated;
  final String? moodEmoji;
  final String? moodLabel;

  const HabitBottomSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconPath,
    required this.isBadHabbit,
    required this.onClose,
    this.onHabitCreated,
    this.moodEmoji,
    this.moodLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.black20,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  title,
                  style: AppFonts.bodyAlternative.copyWith(
                    fontSize: 10,
                    color: AppColors.black40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    onClose();
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CustomHabitScreen(
                          isBadHabit: isBadHabbit,
                          moodEmoji: moodEmoji,
                          moodLabel: moodLabel,
                          onHabitCreated: onHabitCreated,
                        ),
                      ),
                    );
                    if (result != null && onHabitCreated != null) {
                      onHabitCreated!();
                    }
                  },
                  child: Container(
                    height: 70,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.blue100.withOpacity(0.1),
                          AppColors.purple.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.blue100.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blue100.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.blue100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            context.l10n.translate('createCustomHabit'),
                            style: AppFonts.bodyTitleMedium.copyWith(
                              color: AppColors.black100,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.black40,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.translate('popularHabits'),
                  style: AppFonts.bodyAlternative.copyWith(
                    fontSize: 10,
                    color: AppColors.black40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 102,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 24),
              itemCount: LocalizedDefaultHabits.getByType(!isBadHabbit, context).length,
              itemBuilder: (context, index) {
                final habit = LocalizedDefaultHabits.getByType(!isBadHabbit, context)[index];
                return GestureDetector(
                  onTap: () async {
                    onClose();
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CustomHabitScreen(
                          isBadHabit: isBadHabbit,
                          moodEmoji: moodEmoji,
                          moodLabel: moodLabel,
                          selectedHabitName: habit.name,
                          selectedHabitSubtitle: habit.subtitle,
                          selectedHabitEmoji: habit.emoji,
                          selectedHabitColor: habit.color,
                          targetValue: habit.targetValue,
                          targetUnit: habit.targetUnit,
                          motivation: habit.motivation,
                          frequency: habit.frequency,
                          period: habit.period,
                          reminderTime: habit.reminderTime,
                          defaultHabitId: habit.id,
                          onHabitCreated: onHabitCreated,
                        ),
                      ),
                    );
                    if (result != null && onHabitCreated != null) {
                      onHabitCreated!();
                    }
                  },
                  child: Container(
                    width: 94,
                    height: 104,
                    margin: EdgeInsets.only(
                      right: index < LocalizedDefaultHabits.getByType(!isBadHabbit, context).length - 1 ? 12 : 24,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: habit.color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  habit.emoji,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          habit.name,
                          style: AppFonts.bodyTitleMedium.copyWith(
                            color: AppColors.black100,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          habit.subtitle,
                          style: AppFonts.bodyAlternative.copyWith(
                            fontSize: 10,
                            color: AppColors.black60,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
