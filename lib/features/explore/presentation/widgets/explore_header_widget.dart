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
       mainAxisAlignment: MainAxisAlignment.start,
       children: [
         Text(
           header,
           style: AppFonts.headlineH5,
         ),
       ],
     ),
            ],
          ),
        );
  }
}