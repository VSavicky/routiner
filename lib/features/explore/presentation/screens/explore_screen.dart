import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/core/widgets/header.dart';
import 'package:routiner/features/auth/presentation/widgets/auth_header.dart';
import 'package:routiner/features/create_habit/presentation/screens/custom_habit_screen.dart';
import 'package:routiner/features/explore/presentation/widgets/explore_header_widget.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
         ExploreHeaderWidget(header: 'Explore', onPressed: (){}),
        //   SizedBox(
        //     height: 102,
        //     child: ListView.builder(
        //       scrollDirection: Axis.horizontal,
        //       padding: EdgeInsets.only(left: 24), // Только левый отступ
        //       itemCount: DefaultHabits.getByType(!isBadHabbit).length,
        //       itemBuilder: (context, index) {
        //         final habit = DefaultHabits.getByType(!isBadHabbit)[index];
        //         return GestureDetector(
        //           onTap: () async {
        //             onClose();
        //             final result = await Navigator.of(context).push(
        //               MaterialPageRoute(
        //                 builder: (context) => CustomHabitScreen(
        //                   selectedHabitName: habit.name,
        //                   selectedHabitSubtitle: habit.subtitle,
        //                   selectedHabitEmoji: habit.emoji,
        //                   selectedHabitColor: habit.color,
        //                   targetValue: habit.targetValue,
        //                   targetUnit: habit.targetUnit,
        //                   motivation: habit.motivation,
        //                   frequency: habit.frequency,
        //                   period: habit.period,
        //                   reminderTime: habit.reminderTime,
        //                   defaultHabitId: habit.id,
        //                 ),
        //               ),
        //             );
        //           },
        //           child: Container(
        //             width: 140,
        //             margin: EdgeInsets.only(right: index < DefaultHabits.getByType(!isBadHabbit).length - 1 ? 12 : 24),
        //             padding: EdgeInsets.all(16),
        //             decoration: BoxDecoration(
        //               color: habit.color,
        //               borderRadius: BorderRadius.circular(16),
        //             ),
        //           child: Column(
        //             crossAxisAlignment: CrossAxisAlignment.start,
        //             children: [
        //               // Верхняя часть с иконкой
        //               Row(
        //                 children: [
        //                   // Квадрат с иконкой
        //                   Container(
        //                     width: 32,
        //                     height: 32,
        //                     decoration: BoxDecoration(
        //                       color: Colors.white,
        //                       borderRadius: BorderRadius.circular(12),
        //                     ),
        //                     child: Center(
        //                       child: Text(
        //                         habit.emoji,
        //                         style: TextStyle(
        //                           fontSize: 16,
        //                         ),
        //                       ),
        //                     ),
        //                   ),
                          
        //                   Spacer(),
                          
                          
        //                 ],
        //               ),
                      
        //               SizedBox(height: 4),
                      
        //               // Название привычки
        //               Text(
        //                 habit.name,
        //                 style: AppFonts.bodyTitleMedium.copyWith(
        //                   color: AppColors.black100,
        //                   fontSize: 13,
        //                 ),
        //                 maxLines: 1,
        //                 overflow: TextOverflow.ellipsis,
        //               ),
                      
        //               SizedBox(height: 2),
                      
        //               // Подпись
        //               Text(
        //                 habit.subtitle,
        //                 style: AppFonts.bodyAlternative.copyWith(
        //                   fontSize: 10,
        //                   color: AppColors.black60,
        //                 ),
        //                 maxLines: 1,
        //                 overflow: TextOverflow.ellipsis,
        //               ),
        //             ],
        //           ),
        //         ),
        //       );
        //     },
        //   ),
        // ),
        ],
      ),
    );
  }
}

