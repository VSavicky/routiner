import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/features/auth/domain/entities/user_entity.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserEntity? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final docSnapshot = await _firestore.collection('users').doc(currentUser.uid).get();
      if (docSnapshot.exists) {
        setState(() {
          _user = UserEntity.fromMap(docSnapshot.data() as Map<String, dynamic>);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _isLoading 
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Hi, ${_user?.firstName ?? 'User'}',
                  style: AppFonts.headlineH5,
                ),
                const SizedBox(height: 32),
                Text(
                  'Email:',
                  style: AppFonts.bodyTitleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _user?.email ?? 'No data',
                  style: AppFonts.body.copyWith(
                    color: AppColors.black40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Имя:',
                  style: AppFonts.bodyTitleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _user?.firstName ?? 'No data',
                  style: AppFonts.body.copyWith(
                    color: AppColors.black40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Фамилия:',
                  style: AppFonts.bodyTitleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _user?.lastName ?? 'No data',
                  style: AppFonts.body.copyWith(
                    color: AppColors.black40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Дата рождения:',
                  style: AppFonts.bodyTitleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _user?.birthDate ?? 'No data',
                  style: AppFonts.body.copyWith(
                    color: AppColors.black40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Гендер:',
                  style: AppFonts.bodyTitleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _user?.gender ?? 'No data',
                  style: AppFonts.body.copyWith(
                    color: AppColors.black40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Привычки:',
                  style: AppFonts.bodyTitleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _user?.habits.join(', ') ?? 'No data',
                  style: AppFonts.body.copyWith(
                    color: AppColors.black40,
                  ),
                ),
              ],
            ),
      ),
    );
  }
}