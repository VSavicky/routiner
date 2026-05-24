import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/l10n/app_localizations.dart';

class GoalsProgressWidget extends StatelessWidget {
  final int totalGoals;
  final int completedGoals;
  final String? title;
  final AppLocalizations l10n;

  const GoalsProgressWidget({
    Key? key,
    required this.totalGoals,
    required this.completedGoals,
    this.title,
    required this.l10n,
  }) : super(key: key);

  double get _progress {
    if (totalGoals == 0) return 0.0;
    return completedGoals / totalGoals;
  }

  String get _progressPercentage {
    if (totalGoals == 0) return '0%';
    return '${(_progress * 100).round()}%';
  }

  String get _goalsText {
    return '$completedGoals/$totalGoals ${l10n.translate('goalsCompleted')}';
  }

  String get _defaultTitle {
    if (totalGoals == 0) return l10n.translate('noGoalsSetYet');
    if (completedGoals == totalGoals) return l10n.translate('allGoalsCompleted');
    if (completedGoals > totalGoals * 0.75) return l10n.translate('dailyGoalsAlmostDone');
    if (completedGoals > totalGoals * 0.5) return l10n.translate('halfwayThere');
    if (completedGoals > 0) return l10n.translate('keepGoing');
    return l10n.translate('startDailyGoals');
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = title ?? _defaultTitle;
    final progress = _progress;
    final progressPercentage = _progressPercentage;

    return Container(
      width: double.infinity,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purple,
            AppColors.blue,
          ],
          stops: [0.0, 1.0],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Круг загрузки с прогресс-баром
            Container(
              width: 40,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Прогресс-бар
                  Container(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                  // Процент в центре
                  Text(
                    progressPercentage,
                    style: AppFonts.bodyTitleMedium.copyWith(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            // Колонка с текстами
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayTitle,
                    style: AppFonts.bodyTitleMedium.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    _goalsText,
                    style: AppFonts.bodyAlternative.copyWith(
                      color: AppColors.blue40,
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
