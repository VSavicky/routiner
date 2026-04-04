import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/core/widgets/header.dart';
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
  int _selectedToggleIndex = 0; 

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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Header(
        toggleOptions: ['Today', 'Clubs'],
        selectedToggleIndex: _selectedToggleIndex,
        notificationCount: 5, // TODO: Получать из базы данных
        userName: _user?.firstName,
        greeting: _user != null 
            ? 'Hi, ${_user!.firstName}👋' 
            : 'Hi!',
        subtitle: 'Let\'s make habbits toghether!',
        onToggleChanged: (index) {
          setState(() {
            _selectedToggleIndex = index;
          });
          // TODO: Implement period change logic
        },
      ),
    );
  }
}
