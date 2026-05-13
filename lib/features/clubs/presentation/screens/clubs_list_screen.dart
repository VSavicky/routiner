import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/l10n/app_localizations.dart';
import 'club_detail_screen.dart';

class ClubsListScreen extends StatelessWidget {
  const ClubsListScreen({super.key});

  
  @override
  Widget build(BuildContext context) {
    final clubs = [
      {
        'id': 'cat_lovers',
        'name': context.l10n.translate('catLovers'),
        'description': context.l10n.translate('catLoversDescription'),
        'emoji': '🐱',
        'members': '500+',
        'color': const Color(0xFFFF6B6B),
        'habits': [
          {'title': 'Morning pet care', 'emoji': '🐾', 'targetValue': 15, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
          {'title': 'Cat feeding routine', 'emoji': '🥫', 'targetValue': 2, 'targetUnit': 'times', 'incrementStep': 1, 'habitType': 'build'},
          {'title': 'Play with cat', 'emoji': '🎾', 'targetValue': 20, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
        ],
      },
      {
        'id': 'book_worms',
        'name': context.l10n.translate('bookWorms'),
        'description': context.l10n.translate('bookWormsDescription'),
        'emoji': '📚',
        'members': '1.2k',
        'color': const Color(0xFF4ECDC4),
        'habits': [
          {'title': 'Daily reading', 'emoji': '📖', 'targetValue': 30, 'targetUnit': 'min', 'incrementStep': 10, 'habitType': 'build'},
          {'title': 'Book notes', 'emoji': '📝', 'targetValue': 1, 'targetUnit': 'page', 'incrementStep': 1, 'habitType': 'build'},
          {'title': 'Library visit', 'emoji': '🏛️', 'targetValue': 1, 'targetUnit': 'visit', 'incrementStep': 1, 'habitType': 'build'},
        ],
      },
      {
        'id': 'runners',
        'name': context.l10n.translate('runners'),
        'description': context.l10n.translate('runnersDescription'),
        'emoji': '🏃',
        'members': '800+',
        'color': const Color(0xFF95E1D3),
        'habits': [
          {'title': 'Morning run', 'emoji': '🏃', 'targetValue': 5, 'targetUnit': 'km', 'incrementStep': 1, 'habitType': 'build'},
          {'title': 'Stretching', 'emoji': '🤸', 'targetValue': 10, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
          {'title': 'Hydration', 'emoji': '💧', 'targetValue': 8, 'targetUnit': 'glasses', 'incrementStep': 1, 'habitType': 'build'},
        ],
      },
      {
        'id': 'yoga_life',
        'name': context.l10n.translate('yogaLife'),
        'description': context.l10n.translate('yogaLifeDescription'),
        'emoji': '🧘',
        'members': '2k',
        'color': const Color(0xFFA8E6CF),
        'habits': [
          {'title': 'Morning yoga', 'emoji': '🧘', 'targetValue': 20, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
          {'title': 'Meditation', 'emoji': '🧠', 'targetValue': 10, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
          {'title': 'Breathing exercises', 'emoji': '🌬️', 'targetValue': 5, 'targetUnit': 'min', 'incrementStep': 1, 'habitType': 'build'},
        ],
      },
      {
        'id': 'meditation',
        'name': context.l10n.translate('meditationClub'),
        'description': context.l10n.translate('meditationClubDescription'),
        'emoji': '🧠',
        'members': '3k+',
        'color': const Color(0xFFC7CEEA),
        'habits': [
          {'title': 'Daily meditation', 'emoji': '🧘', 'targetValue': 15, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
          {'title': 'Mindful breathing', 'emoji': '🌬️', 'targetValue': 10, 'targetUnit': 'min', 'incrementStep': 2, 'habitType': 'build'},
          {'title': 'Gratitude journal', 'emoji': '📔', 'targetValue': 3, 'targetUnit': 'items', 'incrementStep': 1, 'habitType': 'build'},
        ],
      },
      {
        'id': 'fitness_gurus',
        'name': context.l10n.translate('fitnessGurus'),
        'description': context.l10n.translate('fitnessGurusDescription'),
        'emoji': '💪',
        'members': '1.5k',
        'color': const Color(0xFFFFD93D),
        'habits': [
          {'title': 'Strength training', 'emoji': '💪', 'targetValue': 30, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
          {'title': 'Protein intake', 'emoji': '🥗', 'targetValue': 25, 'targetUnit': 'grams', 'incrementStep': 5, 'habitType': 'build'},
          {'title': 'Recovery stretching', 'emoji': '🤸', 'targetValue': 15, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
        ],
      },
      {
        'id': 'creative_minds',
        'name': context.l10n.translate('creativeMinds'),
        'description': context.l10n.translate('creativeMindsDescription'),
        'emoji': '🎨',
        'members': '750+',
        'color': const Color(0xFFE8B4F8),
        'habits': [
          {'title': 'Daily sketch', 'emoji': '✏️', 'targetValue': 30, 'targetUnit': 'min', 'incrementStep': 10, 'habitType': 'build'},
          {'title': 'Creative writing', 'emoji': '✍️', 'targetValue': 200, 'targetUnit': 'words', 'incrementStep': 50, 'habitType': 'build'},
          {'title': 'Inspiration gathering', 'emoji': '💡', 'targetValue': 15, 'targetUnit': 'min', 'incrementStep': 5, 'habitType': 'build'},
        ],
      },
      {
        'id': 'eco_warriors',
        'name': context.l10n.translate('ecoWarriors'),
        'description': context.l10n.translate('ecoWarriorsDescription'),
        'emoji': '🌱',
        'members': '900+',
        'color': const Color(0xFF90EE90),
        'habits': [
          {'title': 'Recycling', 'emoji': '♻️', 'targetValue': 5, 'targetUnit': 'items', 'incrementStep': 1, 'habitType': 'build'},
          {'title': 'Water conservation', 'emoji': '💧', 'targetValue': 10, 'targetUnit': 'liters', 'incrementStep': 2, 'habitType': 'build'},
          {'title': 'Plastic reduction', 'emoji': '🚫', 'targetValue': 3, 'targetUnit': 'items', 'incrementStep': 1, 'habitType': 'quit'},
        ],
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
                          context.l10n.translate('habitClubs'),
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
          
          // Список клубов
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: clubs.length,
              itemBuilder: (context, index) {
                final club = clubs[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ClubDetailScreen(
                          club: club,
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
                          club['color'] as Color,
                          (club['color'] as Color).withOpacity(0.8),
                        ],
                        stops: [0.0, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          // Иконка клуба
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                club['emoji'] as String,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Информация о клубе
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  club['name'] as String,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  club['description'] as String,
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
                                        '${(club['habits'] as List<dynamic>).length} ${context.l10n.translate('habits')}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      club['members'] as String,
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
