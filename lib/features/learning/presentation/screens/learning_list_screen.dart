import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/l10n/app_localizations.dart';
import 'learning_detail_screen.dart';

class LearningListScreen extends StatelessWidget {
  const LearningListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lessons = [
      {
        'id': 'water_benefits',
        'title': l10n.translate('hydrationScience'),
        'subtitle': l10n.translate('hydrationScienceSubtitle'),
        'emoji': '💧',
        'duration': '5 ${l10n.translate('minRead')}',
        'difficulty': l10n.translate('beginner'),
        'color': const Color(0xFF29B6F6),
        'readTime': 5,
        'category': l10n.translate('healthBasics'),
      },
      {
        'id': 'walking_benefits',
        'title': l10n.translate('walkingForWellness'),
        'subtitle': l10n.translate('walkingForWellnessSubtitle'),
        'emoji': '🚶',
        'duration': '8 ${l10n.translate('minRead')}',
        'difficulty': l10n.translate('beginner'),
        'color': const Color(0xFF66BB6A),
        'readTime': 8,
        'category': l10n.translate('physicalActivity'),
      },
      {
        'id': 'morning_routine',
        'title': l10n.translate('perfectMorning'),
        'subtitle': l10n.translate('perfectMorningSubtitle'),
        'emoji': '🌅',
        'duration': '12 ${l10n.translate('minRead')}',
        'difficulty': l10n.translate('intermediate'),
        'color': const Color(0xFFFFA726),
        'readTime': 12,
        'category': l10n.translate('lifestyle'),
      },
      {
        'id': 'stress_management',
        'title': l10n.translate('stressFreeLiving'),
        'subtitle': l10n.translate('stressFreeLivingSubtitle'),
        'emoji': '🧘',
        'duration': '10 ${l10n.translate('minRead')}',
        'difficulty': l10n.translate('intermediate'),
        'color': const Color(0xFF7E57C2),
        'readTime': 10,
        'category': l10n.translate('mentalHealth'),
      },
      {
        'id': 'sleep_optimization',
        'title': l10n.translate('betterSleep'),
        'subtitle': l10n.translate('betterSleepSubtitle'),
        'emoji': '😴',
        'duration': '15 ${l10n.translate('minRead')}',
        'difficulty': l10n.translate('beginner'),
        'color': const Color(0xFF5B6EFC),
        'readTime': 15,
        'category': l10n.translate('healthBasics'),
      },
      {
        'id': 'nutrition_fundamentals',
        'title': l10n.translate('nutritionEssentials'),
        'subtitle': l10n.translate('nutritionEssentialsSubtitle'),
        'emoji': '🥗',
        'duration': '18 ${l10n.translate('minRead')}',
        'difficulty': l10n.translate('intermediate'),
        'color': const Color(0xFFE91E63),
        'readTime': 18,
        'category': l10n.translate('nutrition'),
      },
      {
        'id': 'productivity_hacks',
        'title': l10n.translate('focusProductivity'),
        'subtitle': l10n.translate('focusProductivitySubtitle'),
        'emoji': '🎯',
        'duration': '7 ${l10n.translate('minRead')}',
        'difficulty': l10n.translate('beginner'),
        'color': const Color(0xFF009688),
        'readTime': 7,
        'category': l10n.translate('lifestyle'),
      },
      {
        'id': 'mindfulness_practice',
        'title': l10n.translate('mindfulnessDaily'),
        'subtitle': l10n.translate('mindfulnessDailySubtitle'),
        'emoji': '🧠',
        'duration': '6 ${l10n.translate('minRead')}',
        'difficulty': l10n.translate('beginner'),
        'color': const Color(0xFF8D6E63),
        'readTime': 6,
        'category': l10n.translate('mentalHealth'),
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header как в других экранах
          Container(
            width: double.infinity,
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.black10, width: 2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: AppColors.black40,
                              size: 20,
                            ),
                          ),
                        ),
                        Text(
                          context.l10n.translate('learning'),
                          style: AppFonts.headlineH5,
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          
          // Список уроков
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => LearningDetailScreen(
                          lesson: lesson,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          lesson['color'] as Color,
                          (lesson['color'] as Color).withOpacity(0.8),
                        ],
                        stops: [0.0, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          // Иконка урока
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                lesson['emoji'] as String,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Информация об уроке
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lesson['title'] as String,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lesson['subtitle'] as String,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        lesson['category'] as String,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        lesson['difficulty'] as String,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      lesson['duration'] as String,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 12,
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
