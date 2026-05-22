import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:routiner/features/habits/data/models/habit_model.dart';
import 'package:routiner/l10n/app_localizations.dart';


class ClubDetailScreen extends StatefulWidget {
  final Map<String, dynamic> club;

  const ClubDetailScreen({
    super.key,
    required this.club,
  });

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> {
  bool _isJoined = false;
  bool _isLoading = false;

  String _getLocalizedHabitName(String habitName) {
    switch (habitName) {
      case 'Morning pet care':
        return context.l10n.translate('morningPetCare');
      case 'Cat feeding routine':
        return context.l10n.translate('catFeedingRoutine');
      case 'Play with cat':
        return context.l10n.translate('playWithCat');
      case 'Daily reading':
        return context.l10n.translate('dailyReading');
      case 'Book notes':
        return context.l10n.translate('bookNotes');
      case 'Library visit':
        return context.l10n.translate('libraryVisit');
      case 'Morning run':
        return context.l10n.translate('morningRun');
      case 'Stretching':
        return context.l10n.translate('stretching');
      case 'Hydration':
        return context.l10n.translate('hydration');
      case 'Morning yoga':
        return context.l10n.translate('morningYoga');
      case 'Meditation':
        return context.l10n.translate('meditation');
      case 'Breathing exercises':
        return context.l10n.translate('breathingExercises');
      case 'Strength training':
        return context.l10n.translate('strengthTraining');
      case 'Protein intake':
        return context.l10n.translate('proteinIntake');
      case 'Recovery stretching':
        return context.l10n.translate('recoveryStretching');
      case 'Daily sketch':
        return context.l10n.translate('dailySketch');
      case 'Creative writing':
        return context.l10n.translate('creativeWriting');
      case 'Inspiration gathering':
        return context.l10n.translate('inspirationGathering');
      case 'Recycling':
        return context.l10n.translate('recycling');
      case 'Water conservation':
        return context.l10n.translate('waterConservation');
      case 'Plastic reduction':
        return context.l10n.translate('plasticReduction');
      default:
        return habitName;
    }
  }

  @override
  void initState() {
    super.initState();
    print('[CLUB DETAIL] Club data received: ${widget.club.keys}');
    final habits = widget.club['habits'] as List<dynamic>? ?? [];
    print('[CLUB DETAIL] Club name: ${widget.club['name']}');
    print('[CLUB DETAIL] Habits count: ${habits.length}');
    for (final habit in habits) {
      print('[CLUB DETAIL]   Habit: ${habit['title']}');
    }
    _checkIfJoined();
  }

  Future<void> _checkIfJoined() async {
    final prefs = await SharedPreferences.getInstance();
    final joinedClubs = prefs.getStringList('joined_clubs') ?? [];
    setState(() {
      _isJoined = joinedClubs.contains(widget.club['id'] as String);
    });
  }

  Future<void> _toggleJoin() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final joinedClubs = prefs.getStringList('joined_clubs') ?? [];
    
    if (_isJoined) {
      // Выход из клуба - удаляем привычки клуба
      joinedClubs.remove(widget.club['id'] as String);
      await _removeClubHabits();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.translate('youLeftTheClub')),
          backgroundColor: Colors.grey,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Присоединение к клубу - добавляем привычки клуба
      joinedClubs.add(widget.club['id'] as String);
      await _addClubHabits();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.trArgs('welcomeToClub', {'name': widget.club['name']})),
          backgroundColor: AppColors.blue100,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    await prefs.setStringList('joined_clubs', joinedClubs);
    
    setState(() {
      _isJoined = !_isJoined;
      _isLoading = false;
    });
  }

  Future<void> _addClubHabits() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;
    final clubHabits = widget.club['habits'] as List<dynamic>? ?? [];

    for (var habitData in clubHabits) {
      final habit = HabitModel(
        id: null, // Firestore сгенерирует ID
        userId: user.uid,
        name: _getLocalizedHabitName(habitData['title'] as String),
        emoji: habitData['emoji'] as String,
        color: '#${(widget.club['color'] as Color).value.toRadixString(16).substring(2).toUpperCase()}',
        habitType: habitData['habitType'] as String,
        targetValue: habitData['targetValue'] as int,
        targetUnit: habitData['targetUnit'] as String,
        incrementStep: habitData['incrementStep'] as int,
        frequency: 1,
        period: 'day',
        remindersEnabled: false,
        reminderTimes: [],
        reminderPeriod: 'Every day',
        motivation: 'Club habit from ${widget.club['name']}',
        isDefaultHabit: false,
        defaultHabitId: null,
        challengeId: 'club_${widget.club['id'] as String}', // Используем challengeId для клубов
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isArchived: false,
      );

      try {
        final docRef = await firestore.collection('habits').add(habit.toFirestore());
        print('[CLUBS] Added club habit: ${habit.name} with ID: ${docRef.id}');
      } catch (e) {
        print('[CLUBS ERROR] Failed to add club habit: $e');
      }
    }
  }

  Future<void> _removeClubHabits() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;

    try {
      // Находим все привычки пользователя из этого клуба
      final habitsQuery = await firestore
          .collection('habits')
          .where('userId', isEqualTo: user.uid)
          .where('challengeId', isEqualTo: 'club_${widget.club['id'] as String}')
          .get();

      // Удаляем каждую привычку клуба
      for (var doc in habitsQuery.docs) {
        await firestore.collection('habits').doc(doc.id).delete();
        print('[CLUBS] Removed club habit: ${doc.id}');
      }
    } catch (e) {
      print('[CLUBS ERROR] Failed to remove club habits: $e');
    }
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
                      widget.club['color'] as Color,
                      (widget.club['color'] as Color).withOpacity(0.8),
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
                        // Большой эмодзи клуба
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
                                widget.club['emoji'] as String,
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Заголовок
                        Text(
                          widget.club['name'] as String,
                          style: AppFonts.headlineH5.copyWith(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        // Подзаголовок
                        Text(
                          widget.club['description'] as String,
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
                                '${(widget.club['habits'] as List<dynamic>?)?.length ?? 0} ${context.l10n.translate('habits')}',
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
                                widget.club['members'] as String,
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
          
          // Контент клуба
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок контента
                  Text(
                    context.l10n.translate('clubHabits'),
                    style: AppFonts.bodyTitleMedium.copyWith(
                      color: AppColors.black100,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Список привычек клуба
                  ...(widget.club['habits'] as List<dynamic>? ?? []).map((habit) {
                    print('[CLUB DETAIL UI] Rendering habit: ${habit['title']}');
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                      child: Row(
                        children: [
                          // Иконка привычки
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: (widget.club['color'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                habit['emoji'] as String,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Информация о привычке
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getLocalizedHabitName(habit['title'] as String),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.black100,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${habit['targetValue']} ${context.l10n.translate(habit['targetUnit'] as String)} ${context.l10n.translate('daily')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.black60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Тип привычки
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (habit['habitType'] as String) == 'quit'
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (habit['habitType'] as String) == 'quit' ? '🔴' : '🟢',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  
                  const SizedBox(height: 24),
                  
                  // Кнопка действия
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _toggleJoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isJoined ? Colors.grey : AppColors.blue100,
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
                              _isJoined ? context.l10n.translate('joinedClub') : context.l10n.translate('joinClub'),
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
}
