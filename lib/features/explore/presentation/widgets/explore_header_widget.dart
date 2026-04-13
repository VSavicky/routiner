import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';

class ExploreHeaderWidget extends StatelessWidget {
  const ExploreHeaderWidget({
    super.key,
    required this.header,
    required this.onPressed,
  });

  final String header;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: double.infinity,
          height: 135,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
     const SizedBox(height: 70),
     Row(
       mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [
         Text(
           header,
           style: AppFonts.headlineH5,
         ),
         GestureDetector(
           onTap: onPressed,
           child: Container(
             width: 48,
             height: 48,
             decoration: BoxDecoration(
               border: Border.all(color: AppColors.black10, width: 2),
               borderRadius: BorderRadius.circular(16),
             ),
             child: const Icon(
               Icons.explore,
               color: AppColors.black40,
               size: 20,
             ),
           ),
         ),
       ],
     ),
            ],
          ),
        );
  }
}