import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:routiner/l10n/app_localizations.dart';

class LearningDetailScreen extends StatefulWidget {
  final Map<String, dynamic> lesson;

  const LearningDetailScreen({
    super.key,
    required this.lesson,
  });

  @override
  State<LearningDetailScreen> createState() => _LearningDetailScreenState();
}

class _LearningDetailScreenState extends State<LearningDetailScreen> {
  bool _isCompleted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfCompleted();
  }

  Future<void> _checkIfCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final completedLessons = prefs.getStringList('completed_lessons') ?? [];
    setState(() {
      _isCompleted = completedLessons.contains(widget.lesson['id'] as String);
    });
  }

  Future<void> _toggleCompletion() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final completedLessons = prefs.getStringList('completed_lessons') ?? [];
    
    if (_isCompleted) {
      completedLessons.remove(widget.lesson['id'] as String);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.translate('lessonMarkedIncomplete')),
          backgroundColor: Colors.grey,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      completedLessons.add(widget.lesson['id'] as String);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.translate('lessonCompleted')),
          backgroundColor: AppColors.blue100,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    await prefs.setStringList('completed_lessons', completedLessons);
    
    setState(() {
      _isCompleted = !_isCompleted;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header с градиентом
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: false,
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(
              color: Colors.white,
              size: 20,
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.lesson['color'] as Color,
                      (widget.lesson['color'] as Color).withOpacity(0.8),
                    ],
                    stops: [0.0, 1.0],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        // Большой эмодзи урока
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                widget.lesson['emoji'] as String,
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Заголовок
                        Text(
                          widget.lesson['title'] as String,
                          style: AppFonts.headlineH5.copyWith(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        // Подзаголовок
                        Text(
                          widget.lesson['subtitle'] as String,
                          style: AppFonts.bodyAlternative.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        // Метаданные
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                widget.lesson['difficulty'] as String,
                                style: AppFonts.bodyAlternative.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                widget.lesson['duration'] as String,
                                style: AppFonts.bodyAlternative.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
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
            ),
          ),
          
          // Контент урока
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Заголовок контента
                Text(
                  'What you\'ll learn',
                  style: AppFonts.bodyTitleMedium.copyWith(
                    color: AppColors.black100,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Блоки с информацией
                _buildContentBlock(
                  '📚 Understanding',
                  _getLessonContent(widget.lesson['id'] as String)['understanding'] ?? '',
                ),
                _buildContentBlock(
                  '🎯 Key Benefits',
                  _getLessonContent(widget.lesson['id'] as String)['benefits'] ?? '',
                ),
                _buildContentBlock(
                  '💡 Practical Tips',
                  _getLessonContent(widget.lesson['id'] as String)['tips'] ?? '',
                ),
                _buildContentBlock(
                  '📈 Implementation',
                  _getLessonContent(widget.lesson['id'] as String)['implementation'] ?? '',
                ),
                
                const SizedBox(height: 24),
                
                // Кнопка действия
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _toggleCompletion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCompleted ? Colors.grey : AppColors.blue100,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _isCompleted ? 'Completed ✓' : 'Mark as Completed',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentBlock(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppFonts.bodyTitleMedium.copyWith(
              color: AppColors.black100,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: AppFonts.bodyAlternative.copyWith(
              color: AppColors.black60,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _getLessonContent(String lessonId) {
    switch (lessonId) {
      case 'water_benefits':
        return {
          'understanding': 'Water makes up about 60% of your body weight and is essential for nearly every bodily function. From regulating temperature to lubricating joints, proper hydration is fundamental to optimal health and performance.',
          'benefits': '• Increased energy and mental clarity\n• Improved skin health and appearance\n• Better digestion and nutrient absorption\n• Enhanced physical performance and recovery\n• Stronger immune system function',
          'tips': '• Start your day with a glass of water\n• Keep a reusable water bottle nearby\n• Set reminders to drink regularly\n• Flavor water with fruits if plain water is boring\n• Monitor your urine color as a hydration indicator',
          'implementation': 'Begin with 8 glasses (64oz) daily and adjust based on your activity level, climate, and individual needs. Spread intake throughout the day rather than drinking large amounts at once.'
        };
      case 'walking_benefits':
        return {
          'understanding': 'Walking is one of the most accessible forms of exercise that offers tremendous health benefits without requiring special equipment or intense physical exertion.',
          'benefits': '• Improved cardiovascular health\n• Stronger bones and muscles\n• Better mood and mental health\n• Weight management and metabolism boost\n• Reduced risk of chronic diseases',
          'tips': '• Start with 10-15 minute daily walks\n• Maintain good posture while walking\n• Choose comfortable, supportive footwear\n• Vary your walking routes for interest\n• Listen to podcasts or music for enjoyment',
          'implementation': 'Aim for 30 minutes of brisk walking most days of the week. This can be broken into shorter 10-minute walks throughout the day for the same benefits.'
        };
      case 'morning_routine':
        return {
          'understanding': 'How you start your day sets the tone for everything that follows. A well-designed morning routine can transform your productivity, mood, and overall life satisfaction.',
          'benefits': '• Reduced stress and anxiety\n• Increased productivity and focus\n• Better time management\n• Improved sleep quality\n• Enhanced self-discipline and confidence',
          'tips': '• Prepare the night before\n• Wake up at the same time daily\n• Avoid checking phone first thing\n• Include movement or stretching\n• Practice gratitude or meditation',
          'implementation': 'Start small with 2-3 key activities and gradually build your routine over 2-3 weeks. Consistency matters more than intensity when building new habits.'
        };
      default:
        return {
          'understanding': 'Lesson content coming soon...',
          'benefits': '• Loading benefits...\n• More to come...',
          'tips': '• Tips coming soon...\n• Check back later...',
          'implementation': 'Implementation details will be added soon...'
        };
    }
  }
}
