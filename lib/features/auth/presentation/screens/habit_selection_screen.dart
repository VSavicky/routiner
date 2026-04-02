import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/features/auth/presentation/widgets/auth_header.dart';
import 'package:routiner/features/auth/presentation/widgets/primary_button.dart';

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
                    text: 'Complete',
                    onPressed: _selectedHabit != null ? () {
                      context.go('/home');
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
