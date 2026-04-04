import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/features/auth/presentation/widgets/auth_header.dart';
import 'package:routiner/features/auth/presentation/widgets/primary_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HabitSelectionScreen extends StatefulWidget {
  const HabitSelectionScreen({super.key});

  @override
  State<HabitSelectionScreen> createState() => _HabitSelectionScreenState();
}

class _HabitSelectionScreenState extends State<HabitSelectionScreen> {
  String? _selectedHabit;
  
  final List<Map<String, String>> habits = [
    {'emoji': '🏃‍♂️', 'name': 'Running'},
    {'emoji': '🧘‍♀️', 'name': 'Meditation'},
    {'emoji': '📚', 'name': 'Reading'},
    {'emoji': '💪', 'name': 'Fitness'},
    {'emoji': '🥗', 'name': 'Healthy Eating'},
    {'emoji': '💧', 'name': 'Drinking Water'},
    {'emoji': '😴', 'name': 'Sleep Schedule'},
    {'emoji': '✍️', 'name': 'Journaling'},
    {'emoji': '🎨', 'name': 'Creative Work'},
    {'emoji': '🚴‍♀️', 'name': 'Cycling'},
  ];

  Future<void> _saveUserDataAndNavigate() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && _selectedHabit != null) {
        // Получаем сохраненные данные из SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final email = prefs.getString('registration_email') ?? '';
        final password = prefs.getString('registration_password') ?? '';
        final firstName = prefs.getString('registration_first_name') ?? '';
        final lastName = prefs.getString('registration_last_name') ?? '';
        final birthDate = prefs.getString('registration_birth_date') ?? '';
        final gender = prefs.getString('registration_gender') ?? '';
        
        // Обновляем запись в Firestore с гендером и привычкой
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'gender': gender,
          'habits': [_selectedHabit!],
        });
        
        // Очищаем временные данные
        await prefs.remove('registration_email');
        await prefs.remove('registration_password');
        await prefs.remove('registration_first_name');
        await prefs.remove('registration_last_name');
        await prefs.remove('registration_birth_date');
        await prefs.remove('registration_gender');
        
        // Переходим на главный экран
        if (mounted) {
          while (context.canPop()) {
            context.pop();
          }
          context.go('/home');
        }
      }
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AuthHeader(
            title: 'Create Account',
            onBackPressed: () {
              context.go('/gender');
            },
          ),
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Choose your first habits',
                            style: AppFonts.bodyTitleMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'You may add more habits later',
                            style: AppFonts.body.copyWith(
                              color: AppColors.black60,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 160 / 134,
                          ),
                          itemCount: habits.length,
                          itemBuilder: (context, index) {
                            final habit = habits[index];
                            final isSelected = _selectedHabit == habit['name'];
                            
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedHabit = habit['name'];
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected 
                                        ? AppColors.blue100 
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      habit['emoji']!,
                                      style: const TextStyle(fontSize: 32),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      habit['name']!,
                                      style: AppFonts.bodyTitleMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 20,
                  child: PrimaryButton(
                    text: 'Next',
                    onPressed: _selectedHabit != null ? () {
                      _saveUserDataAndNavigate();
                    } : null,
                    isActive: _selectedHabit != null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
