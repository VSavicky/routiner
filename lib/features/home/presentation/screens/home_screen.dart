import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';
import 'package:routiner/core/widgets/header.dart';
import 'package:routiner/core/widgets/week_days_list.dart';
import 'package:routiner/core/widgets/challenges_widget.dart';
import 'package:routiner/core/widgets/goals_progress_widget.dart';
import 'package:routiner/features/auth/domain/entities/user_entity.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  
  UserEntity? _user;
  bool _isLoading = true;
  int _selectedToggleIndex = 0;
  DateTime? _selectedDate; // Для выбора даты 

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      body: Column(
        children: [
          Header(
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
                if (index == 0 && _selectedToggleIndex == 0) {
                  // Повторное нажатие на Today - скролл наверх
                  _scrollController.animateTo(
                    0,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
                _selectedToggleIndex = index;
              });
              // TODO: Implement period change logic
            },
          ),
          // Список дней недели или страница Clubs
          Expanded(
            child: _selectedToggleIndex == 0 
                ? SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        WeekDaysList(
                          selectedDate: _selectedDate,
                          onDateSelected: (date) {
                            setState(() {
                              _selectedDate = date;
                            });
                            // TODO: Implement date selection logic
                          },
                        ),
                        // Колонка с целями
                        Padding(
                          padding: const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Виджет выполнения целей
                              GoalsProgressWidget(
                                totalGoals: 4,
                                completedGoals: 1,
                              ),
                              SizedBox(height: 16),
                              // Виджет челенджей
                              ChallengesWidget(
                                title: 'Best Runners!',
                                subtitle: '5 days 13 ours left',
                                friendsCount: 3,
                                onViewAllPressed: () {
                                  // TODO: Обработать нажатие на VIEW ALL
                                  print('VIEW ALL pressed');
                                },
                                onContainerPressed: () {
                                  // TODO: Обработать нажатие на контейнер
                                  print('Container pressed');
                                },
                                onFriendsPressed: () {
                                  // TODO: Обработать нажатие на друзей
                                  print('Friends pressed');
                                },
                                onAddFriendPressed: () {
                                  // TODO: Обработать нажатие на добавление друга
                                  print('Add friend pressed');
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildClubsPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildClubsPage() {
    return Center(
      child: Text(
        'Clubs',
        style: AppFonts.headlineH5.copyWith(
          color: AppColors.black100,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
