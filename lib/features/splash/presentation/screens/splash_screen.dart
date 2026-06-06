import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routiner/features/auth/domain/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  
  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {
    // Ждем 2 секунды для splash эффекта
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      // Проверяем первый запуск
      final prefs = await SharedPreferences.getInstance();
      final isFirstRun = prefs.getBool('is_first_run') ?? true;
      
      if (isFirstRun) {
        // Первый запуск - показываем onboarding
        await prefs.setBool('is_first_run', false);
        context.pushReplacement('/onboarding');
      } else {
        // Не первый запуск - проверяем авторизацию
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          // Пользователь авторизован в Firebase - проверяем есть ли данные в Firestore
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(firebaseUser.uid)
                .get();
            
            if (userDoc.exists) {
              // Данные есть - онбординг завершён, на главный экран
              context.pushReplacement('/home');
            } else {
              // Данных нет - онбординг не завершён, на выбор гендера
              context.pushReplacement('/gender');
            }
          } catch (e) {
            // Ошибка - на авторизацию
            context.pushReplacement('/auth');
          }
        } else {
          // Пользователь не авторизован - на onboarding
          context.pushReplacement('/onboarding');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3843FF), // Фиолетовый фон
      body: Center(
        child: Image.asset(
          'assets/images/Logo.png', // Логотип из ассетов
          width: 120,
          height: 120,
        ),
      ),
    );
  }
}
