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
    final l10n = context.l10n;
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
                  l10n.translate('youWillLearn'),
                  style: AppFonts.bodyTitleMedium.copyWith(
                    color: AppColors.black100,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Блоки с информацией
                _buildContentBlock(
                  '📚 ${l10n.translate('understandingBlock')}',
                  _getLessonContent(widget.lesson['id'] as String, l10n)['understanding'] ?? '',
                ),
                _buildContentBlock(
                  '🎯 ${l10n.translate('keyBenefits')}',
                  _getLessonContent(widget.lesson['id'] as String, l10n)['benefits'] ?? '',
                ),
                _buildContentBlock(
                  '💡 ${l10n.translate('practicalTips')}',
                  _getLessonContent(widget.lesson['id'] as String, l10n)['tips'] ?? '',
                ),
                _buildContentBlock(
                  '📈 ${l10n.translate('implementation')}',
                  _getLessonContent(widget.lesson['id'] as String, l10n)['implementation'] ?? '',
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
                            _isCompleted ? '${l10n.translate('completed')} ✓' : l10n.translate('markAsCompleted'),
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

  Map<String, String> _getLessonContent(String lessonId, AppLocalizations l10n) {
    switch (lessonId) {
      case 'water_benefits':
        return {
          'understanding': l10n.translate('waterUnderstanding'),
          'benefits': l10n.translate('waterBenefits'),
          'tips': l10n.translate('waterTips'),
          'implementation': l10n.translate('waterImplementation'),
        };
      case 'walking_benefits':
        return {
          'understanding': l10n.translate('walkingUnderstanding'),
          'benefits': l10n.translate('walkingBenefits'),
          'tips': l10n.translate('walkingTips'),
          'implementation': l10n.translate('walkingImplementation'),
        };
      case 'morning_routine':
        return {
          'understanding': l10n.translate('morningUnderstanding'),
          'benefits': l10n.translate('morningBenefits'),
          'tips': l10n.translate('morningTips'),
          'implementation': l10n.translate('morningImplementation'),
        };
      default:
        return {
          'understanding': l10n.translate('lessonContentComingSoon'),
          'benefits': '• ${l10n.translate('lessonLoadingBenefits')}\n• ${l10n.translate('lessonMoreToCome')}',
          'tips': '• ${l10n.translate('lessonTipsComingSoon')}\n• ${l10n.translate('lessonCheckBackLater')}',
          'implementation': l10n.translate('lessonImplementationSoon'),
        };
    }
  }
}
